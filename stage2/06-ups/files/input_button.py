import logging, os, time, platform, struct, subprocess, sys, typing
from datetime import datetime
from threading import Thread, Lock

BUTTON_PRESS = 1
BUTTON_RELEASE = 2
BUTTON_BLINK = 3

# BLINKING_TOLERANCE - number of seconds to wait for a new pressed/released signal
# before deciding if a "blink" has happened. Increasing this too much delays the
# detection of the release event, consequently when power disconnects the script
# will only detect it after `BLINKING_TOLERANCE` seconds and not one milisecond earlier
BLINKING_TOLERANCE = 4.5  # seconds

ButtonEvent = typing.NamedTuple("ButtonEvent", [("event", int), ("timestamp", datetime)])


"""
v2.0 Test cases, when nearly full battery

Test 1
1. initial status: plugged-in
2. start the script
3. record button status    - pressed
4. unplug + record         - received released event, released
5. plug in + record        - received pressed event, received held event, pressed
6. unplug + record         - received released event, released
7. plug in + record        - received pressed event, received held event, pressed

Test 2
1. initial status: unplugged
2. start the script
3. record button status    - released
4. plug in + record        - received pressed event, received held event, pressed
5. unplug + record         - received released event, released
6. plug in + record        - received pressed event, received held event, pressed
7. unplug + record         - received released event, released
"""


class ConsistentButton(Thread):
    def __init__(self, button: "gpiozero.Button"):
        super().__init__()
        self.button = button
        self.button.when_pressed = self._button_pressed
        self.button.when_released = self._button_released
        self.button.when_held = self._button_held
        self._events = []
        self._max_events = 4
        self.when_pressed = None
        self.when_released = None
        self.when_held = None
        self.running = False
        self._state_lock = Lock()
        self._state = None
        self._previous_state = None

    @property
    def is_pressed(self):
        return self.button.is_pressed

    def run(self):
        self.running = True
        self._cycle(self.button.is_pressed)

        while self.running:
            try:
                time.sleep(0.5)
                self._cycle(self.button.is_pressed)
            except KeyboardInterrupt:
                self.running = False
                raise
            except Exception:
                raise

    def stop(self):
        self.running = False
        self.join()

    def _cycle(self, current_state):
        with self._state_lock:
            self._previous_state = self._state
            self._state = current_state

            if self._state == self._previous_state:
                return

            self._do_callbacks(BUTTON_PRESS if self._state else BUTTON_RELEASE)

    def _button_pressed(self):
        self._append_event(BUTTON_PRESS)
        self._cycle(self.button.is_pressed)

    def _button_released(self):
        self._append_event(BUTTON_RELEASE)
        self._cycle(self.button.is_pressed)

    def _button_held(self):
        if self.when_held is not None:
            self.when_held()

    def _append_event(self, event):
        now = datetime.utcnow()
        self._events = [*self._events[1 - self._max_events :], ButtonEvent(event=event, timestamp=now)]

    def _do_callbacks(self, state):
        if state == BUTTON_PRESS and self.when_pressed is not None:
            self.when_pressed()

        elif state == BUTTON_RELEASE and self.when_released is not None:
            self.when_released()

        elif state == BUTTON_BLINK and self.when_blinking is not None:
            self.when_blinking()


class BlinkingButton(ConsistentButton):
    def __init__(self, button: "gpiozero.Button"):
        super().__init__(button)

        self.when_blinking = None
        self._is_pressed = self.button.is_pressed
        self.blink_duration = BLINKING_TOLERANCE
        self._supressed_latest_event = False
        self._latest_blink_time = None

    @property
    def is_pressed(self):
        return self._is_pressed

    def _cycle(self, current_state):
        states = {True: BUTTON_PRESS, False: BUTTON_RELEASE}
        if isinstance(current_state, bool):
            current_state = states[current_state]

        now = datetime.utcnow()
        delta = 3600.0
        if len(self._events) >= 2:
            delta = (now - self._events[-2].timestamp).total_seconds()

        with self._state_lock:
            self._previous_state = self._state
            self._state = current_state

            if self._state == self._previous_state:
                if self._supressed_latest_event and delta > self.blink_duration * 1.5:
                    self._is_pressed = current_state == BUTTON_PRESS
                    self._latest_blink_time = None
                    self._supressed_latest_event = False
                    self._do_callbacks(self._state)

            elif self._check_blinking():
                self._supressed_latest_event = True
                if self._latest_blink_time is None:
                    self._is_pressed = True
                    self._latest_blink_time = now
                    self._supressed_latest_event = True
                    self._do_callbacks(BUTTON_BLINK)

            elif delta > self.blink_duration * 1.5:
                self._is_pressed = current_state == BUTTON_PRESS
                self._latest_blink_time = None
                self._supressed_latest_event = False
                self._do_callbacks(current_state)

            else:
                self._supressed_latest_event = True

    def _check_blinking(self):
        pressed_count = len([e for e in self._events if e.event == BUTTON_PRESS])
        released_count = len([e for e in self._events if e.event == BUTTON_RELEASE])

        threshold = 0.4 * self._max_events
        if pressed_count >= threshold and released_count >= threshold:
            latest = self._events[-1]
            oldest = self._events[0]
            delta = latest.timestamp - oldest.timestamp
            if delta.total_seconds() <= self.blink_duration * 2.0:
                return True
        return False
