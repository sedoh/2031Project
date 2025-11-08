# Peripheral for SCOMP Processor - ECE 2031 Project

## Modulus: a mod b = result 
  ### *Memory mapping*
  
  | Function | Address | Direction | Description |
  | ----------- | ----------- | ----------- | ----------- |
  | A operand| 0xF0 | Write | First operand for modulus
  | B operand | 0xF1 | Write | Second operand for modulus
  | Start | 0xF2 | Write | Writing 1 starts mod operation 
  | Result | 0xF3 | Read | Contains the result of the operation
  | Status | 0xF4 | Read | 1 if done, 0 if busy
  
