# Peripheral for SCOMP Processor - ECE 2031 Project

## Modulus: A mod B = Result 
***A Operand (address 0xF0), Write***<br />
a[15:0] register takes in data written to the peripheral from the processor representing the A operand of the mod operation. 

***B Operand (address 0xF1), Write***<br />
b[15:0] register that takes in data written to the peripheral from the processor representing the B operand of the mod operation.

***Start (address 0xF2), Write***<br />
Start[0] register is given the value of 1 if the processor is writing to the peripheral and the mod operation is underway. It is given the value of 0 if no writing is occuring from the processor to the peripheral, meaning the mod operation is finished. 

***Result (address 0xF3), Read***<br />
result[15:0] register feeds data being read from the peripheral into the processor representing the result of the mod operation. 

***Done (address 0xF4), Read***<br />
done[0] register is given the value of 1 if the mod operation is finished and 0 if the the operation is still underway.

  ### *Register mapping*
  
  | Address | Register Name | Bits | Description |
  | ----------- | ----------- | ----------- | ----------- |
  | 0xF0 | A operand | a[15:0] | First operand for modulus
  | 0xF1 | B operand | b[15:0] | Second operand for modulus
  | 0xF2 | Start | start[0] | Writing 1 starts mod operation 
  | 0xF3 | Result | result[15:0] | Contains the result of the operation
  | 0xF4 | Done | done[0] | 1 if done, 0 if busy

