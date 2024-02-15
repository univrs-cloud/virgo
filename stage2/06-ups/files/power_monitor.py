import logging, time, struct, subprocess
import smbus

from datetime import datetime
from threading import Thread, Lock

from .input_button import ConsistentButton
from .settings import is_development

GRID_POWER = "grid"
BATTERY_POWER = "battery"


class SystemPower:
    def __init__(self, button):
        self.bus = smbus.SMBus(1)  # 0 = /dev/i2c-0 (port I2C0), 1 = /dev/i2c-1 (port I2C1)

        self.voltage = None
        self.capacity = None
        self.primary_power_source = None
        self.is_running_from_battery = None
        self.has_read_errors = False
        self.running = False
        self.low_capacity_threshold = 50
        self.has_issued_shutdown = False
        self.issued_shutdown_timestamp = None

        self.power_source_button = button
        self.power_source_button.when_pressed = self._running_from_grid
        self.power_source_button.when_blinking = self._running_from_grid_charging
        self.power_source_button.when_released = self._running_from_battery
        self.power_source_button.when_held = self._beeing_held

        self._read_power_values()
        self.power_source_button.start()

    def _read_voltage(self):
        address = 0x36
        read = self.bus.read_word_data(address, 2)
        swapped = struct.unpack("<H", struct.pack(">H", read))[0]
        self.voltage = swapped * 1.25 / 1000 / 16
        return self.voltage

    def _read_capacity(self):
        address = 0x36
        read = self.bus.read_word_data(address, 4)
        swapped = struct.unpack("<H", struct.pack(">H", read))[0]
        self.capacity = int(swapped / 256)
        return self.capacity

    def _read_primary_power_source(self):
        primary_power_source = GRID_POWER if self.power_source_button.is_pressed else BATTERY_POWER
        self.set_primary_power_source(primary_power_source, log_change=True)

    def _beeing_held(self):
        pass

    def _running_from_grid_charging(self):
        self.set_primary_power_source(GRID_POWER, log_change=True)

    def _running_from_grid(self):
        self.set_primary_power_source(GRID_POWER, log_change=True)

    def _running_from_battery(self):
        self._read_power_values()
        self.set_primary_power_source(BATTERY_POWER, log_change=True)
        if self.running and self.has_critical_battery_power():
            self.shutdown()

    def _read_power_values(self):
        readers = [
            {"name": "voltage", "func": self._read_voltage},
            {"name": "capacity", "func": self._read_capacity},
            {"name": "primary power source", "func": self._read_primary_power_source},
        ]
        has_errors = False
        for reader in readers:
            label = reader.get("name")
            reader_func = reader.get("func")
            try:
                reader_func()
            except KeyboardInterrupt:
                raise
            except Exception as e:
                has_errors = True
                msg = str(e) or type(e).__name__
                logging.warning(f"Failed to read {label}: {msg}")
        self.has_read_errors = has_errors

    def set_primary_power_source(self, primary_power_source, log_change=False):
        if self.primary_power_source and self.primary_power_source != primary_power_source:
            f = open("/tmp/ups_power_source", "w")
            f.write(str(primary_power_source))
            f.close()

        if log_change and self.primary_power_source and self.primary_power_source != primary_power_source:
            logging.info(f"Primary power source switched from {self.primary_power_source} to {primary_power_source}")

        self.primary_power_source = primary_power_source
        self.is_running_from_battery = self.primary_power_source == BATTERY_POWER

    def status(self):
        return f"Battery: {self.capacity:2}% ({self.voltage:4.2f}V), primary power: {self.primary_power_source}"

    def has_critical_battery_power(self):
        return self.is_running_from_battery and (self.capacity <= self.low_capacity_threshold)

    def shutdown(self):
        if self.has_issued_shutdown:
            return
        try:
            logging.critical(
                f"Issuing shutdown command (Battery: {self.capacity:2}%, threshold: {self.low_capacity_threshold:2}%)"
            )
            if is_development():
                subprocess.check_call(["echo", "shutdown now"], shell=False)
            else:
                subprocess.check_call(["shutdown", "-h", "now"], shell=False)
            self.has_issued_shutdown = True
            self.issued_shutdown_timestamp = datetime.utcnow()
        except KeyboardInterrupt:
            self.has_issued_shutdown = False
            self.issued_shutdown_timestamp = None
            raise
        except Exception as e:
            self.has_issued_shutdown = False
            self.issued_shutdown_timestamp = None
            msg = str(e) or type(e).__name__
            logging.warning(f"Failed to issue shutdown command: {msg}")

    def stop(self):
        self.running = False
        if isinstance(self.power_source_button, Thread):
            self.power_source_button.stop()

    def monitor_forever(self, max_interval=60):
        f = open("/tmp/ups_power_source", "w")
        f.write(str(self.primary_power_source))
        f.close()
        now = datetime.utcnow()
        self.running = True
        while self.running:
            uptime = datetime.utcnow() - now
            self._read_power_values()
            min_interval = 1 if self.is_running_from_battery else max(10, max_interval / 2.0)
            interval = scaled_value(
                self.capacity, self.low_capacity_threshold, self.low_capacity_threshold + 15, min_interval, max_interval
            )
            uptime_minutes = uptime.total_seconds() / 60.0
            if interval > 45:
                logging.info(f"[{uptime_minutes:5.0f}] {self.status()}")
            else:
                logging.info(f"[{uptime_minutes:7.2f}] {self.status()}")

            if self.running and self.has_critical_battery_power():
                self.shutdown()
            time.sleep(interval)

    def log_forever(self, interval=5):
        now = datetime.utcnow()
        self.running = True
        while self.running:
            uptime = datetime.utcnow() - now
            self._read_power_values()
            logging.info(f"[{uptime.total_seconds():4.0f}] {self.status()}")
            time.sleep(interval)


def scaled_value(inp_value, inp_min, inp_max, out_min, out_max):
    if inp_min >= inp_max:
        raise ValueError(f"invalid input interval: {inp_min}, {inp_max}")
    if out_min >= out_max:
        raise ValueError(f"invalid output interval: {out_min}, {out_max}")

    inp_value = max(inp_value, inp_min)
    inp_value = min(inp_value, inp_max)

    out_delta = (inp_value - inp_min) * (out_max - out_min) / (inp_max - inp_min)
    return out_min + out_delta
