import logging, os

def is_development():
    debug = os.environ.get("DEBUG", None)
    return debug is not None and debug.lower() not in ["no", "false"]
