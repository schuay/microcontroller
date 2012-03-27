.section .data
data_start:
    .long 5,1,6,25,2,6,12,623,23,124,4,9

.section .text
.globl bsort

.equ DATA_LEN,  12
.equ ST_DATA_LEN, 16
.equ ST_DATA_START, 24

.type bsort, @function
bsort:
    push    %rbp
    movq    %rsp, %rbp  # set base pointer

    push    %rsi
    push    %rdi
sort:
    call    f_iterate

    cmpl    $0, %eax
    jne     sort

    mov     %rbp, %rsp
    pop     %rbp
    ret

.equ r_data_start, %rbx
.equ index, %rcx
.equ prev, %edx
.equ current, %eax
.equ swapcount, %esi

# f_iterate(len, start)

.type f_iterate, @function
f_iterate:
    push   %rbp
    movq    %rsp, %rbp

    push    %rbx        # rbx is saved by callee

    movq    ST_DATA_LEN(%rbp), index
    movq    ST_DATA_START(%rbp), r_data_start

    movl    $0, swapcount

    cmpq    $1, index   # if < 2 elements in array
    jle      exit       # return

    movl    -8(r_data_start, index, 8), current
    decq    index

loop_start:
    movl    current, prev
    movl    -8(r_data_start, index, 8), current

    cmpl    current, prev   # if prev >= current, continue
    jge      loop_end

    movl    prev, -8(r_data_start, index, 8) # otherwise, swap elements
    movl    current, (r_data_start, index, 8)
    incl    swapcount

loop_end:
    loop    loop_start

exit:
    pop     %rbx    # restore rbx

    movl    swapcount, %eax

    movq    %rbp, %rsp
    pop    %rbp
    ret
