#!/usr/bin/env python3

import logging, platform, sys
import smbus

from datetime import datetime
from gpiozero import Button
from logging.config import dictConfig
from logging.handlers import SysLogHandler
from threading import Thread, Lock

from .input_button import BlinkingButton
from .power_monitor import SystemPower
from .settings import is_development


def make_stdout_handler():
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(
        logging.Formatter(
            "%(asctime)s devel %(levelname)s [%(module)s] [PID %(process)d] %(message)s", "%b %d %H:%M:%S"
        )
    )
    return handler


def make_syslog_handler():
    handler = None
    if platform.system() == "Darwin":
        handler = SysLogHandler("/var/run/syslog")
    else:  # if platform.system() == 'Linux':
        handler = SysLogHandler("/dev/log")
    handler.setFormatter(logging.Formatter("%(levelname)s [%(module)s] [PID %(process)d] %(message)s"))
    return handler


def logging_setup():
    logger = logging.getLogger()
    if not is_development():
        logger.addHandler(make_syslog_handler())
    else:
        logger.addHandler(make_stdout_handler())
    logger.setLevel(logging.DEBUG)


def main():
    logging.info("Starting ups power management")
    ups = SystemPower(BlinkingButton(Button(6)))
    try:
        if is_development():
            ups.log_forever(interval=1.5)
        else:
            ups.monitor_forever()
    except KeyboardInterrupt:
        print("\n[Ctrl-C] received, exiting...")
    finally:
        logging.info("Exiting")
        ups.stop()


if __name__ == "__main__":
    logging_setup()
    main()
