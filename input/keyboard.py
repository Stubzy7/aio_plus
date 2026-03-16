from pal import keyboard as _kb

VK_MAP = _kb.VK_MAP
EXTENDED_KEYS = getattr(_kb, 'EXTENDED_KEYS', set())

_vk_from_name = _kb._vk_from_name
key_down = _kb.key_down
key_up = _kb.key_up
key_press = _kb.key_press
send = _kb.send
send_text = _kb.send_text
send_text_vk = _kb.send_text_vk
control_send = _kb.control_send
control_send_text = _kb.control_send_text
_make_lparam = getattr(_kb, '_make_lparam', lambda vk, up=False: 0)
