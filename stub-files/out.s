section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, 13
  mov [esp-4], eax
  mov eax, 1234
  mov [esp-8], eax
  mov eax, [esp-4]
  mov [esp-8], eax
  mov eax, [esp-8]
  add eax, 1
  mov [esp-12], eax
  mov eax, 3
  add eax, -1
  mov [esp-16], eax
  mov eax, [esp-12]
  add eax, -1
  ret
