import logging
import inspect

class Logger:
    def __init__(self, name="Logger", global_title=None):
        self.logger = logging.getLogger(name)
        if not self.logger.hasHandlers():
            handler = logging.StreamHandler()
            formatter = logging.Formatter("[%(name)s] [%(levelname)s] [%(funcName)s] %(message)s")
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)
        self.global_title = global_title

    def info(self, message):
        self._log(message, level="info")

    def warning(self, message):
        self._log(message, level="warning")

    def error(self, message):
        self._log(message, level="error")

    def _log(self, message, level):
        func_name = inspect.stack()[2].function  # Automatically gets the caller function name
        formatted_message = f"[{func_name}] {message}"

        if level == "info":
            self.logger.info(formatted_message)
        elif level == "warning":
            self.logger.warning(formatted_message)
        elif level == "error":
            self.logger.error(formatted_message)
        else:
            raise ValueError(f"Unsupported logging level: {level}")
