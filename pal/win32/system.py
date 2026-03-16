import ctypes
import ctypes.wintypes as wt

def acquire_mutex(name: str = "GG_AIO_MUTEX"):
    mutex = ctypes.windll.kernel32.CreateMutexW(None, True, name)
    already_exists = ctypes.windll.kernel32.GetLastError() == 183
    return mutex, not already_exists

def release_mutex(mutex):
    if mutex:
        ctypes.windll.kernel32.ReleaseMutex(mutex)
        ctypes.windll.kernel32.CloseHandle(mutex)

def message_box(text: str, title: str = "GG AIO", flags: int = 0x30):
    ctypes.windll.user32.MessageBoxW(0, text, title, flags)

def begin_timer_period(ms: int = 1):
    ctypes.windll.winmm.timeBeginPeriod(ms)

def end_timer_period(ms: int = 1):
    ctypes.windll.winmm.timeEndPeriod(ms)

def get_async_key_state(vk: int) -> bool:
    return bool(ctypes.windll.user32.GetAsyncKeyState(vk) & 0x8000)
