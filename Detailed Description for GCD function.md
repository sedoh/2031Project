### **Greatest Common Divisor: gcd(A, B) = Result**

##### 

##### **A Operand (address 0xE0), Write**



###### a\[15:0] register takes in data written to the peripheral from the processor, representing the A operand of the GCD operation.



##### 

##### **B Operand (address 0xE1), Write**



###### b\[15:0] register takes in data written to the peripheral from the processor, representing the B operand of the GCD operation.



##### 

##### **Start (address 0xE2), Write**



###### start\[0] register is given the value of 1 when the processor writes to the peripheral to begin the GCD operation.

###### Once the computation starts, the peripheral automatically clears the start bit back to 0.

###### The processor can monitor the Done register to determine when the operation has completed.



##### 

##### **Result (address 0xE3), Read**



###### result\[15:0] register provides the GCD result of the operation once computation is finished.

###### The processor reads this value after the Done bit indicates completion.



##### 

##### **Done (address 0xE4), Read**



###### done\[0] register outputs 1 when the GCD operation is finished and 0 when the operation is still underway.

###### Reading this register clears the done bit back to 0 for the next operation.



##### **Operation Description**



###### When the processor writes operands A and B followed by writing 1 to the Start register,

###### the GCD peripheral begins executing the binary GCD algorithm (Stein’s algorithm) in hardware.

###### The peripheral uses bitwise shifts and subtraction operations to compute the GCD efficiently without requiring division hardware.

###### Once the result is computed, it is placed in the Result register, and the Done flag is set to 1 to signal completion.

###### 

##### **Special Cases**



###### gcd(0, x) = x

###### 

###### gcd(x, 0) = x

###### 

###### gcd(0, 0) = 0 (no error flag; result defaults to 0)

###### 

###### Writing a new Start = 1 while a previous operation is still running is ignored until Done = 1.



##### **Register Mapping**



###### | Address  | Register Name | Bits         | Description                          |

###### | -------- | ------------- | ------------ | ------------------------------------ |

###### | \*\*0x90\*\* | \*\*A operand\*\* | a\[15:0]      | First operand for GCD                |

###### | \*\*0x91\*\* | \*\*B operand\*\* | b\[15:0]      | Second operand for GCD               |

###### | \*\*0x92\*\* | \*\*Start\*\*     | start\[0]     | Writing 1 starts GCD operation       |

###### | \*\*0x93\*\* | \*\*Result\*\*    | result\[15:0] | Contains the result of the operation |

###### | \*\*0x94\*\* | \*\*Done\*\*      | done\[0]      | 1 if done, 0 if still busy           |



###### **Suggest Mapping in ASM:**

**GCD\_A       .FILL 0x0090**

**GCD\_B       .FILL 0x0091**

**GCD\_START   .FILL 0x0092**

**GCD\_RESULT  .FILL 0x0093**

**GCD\_DONE    .FILL 0x0094**

###### 

