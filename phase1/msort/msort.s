.equ ST_PTR, -8
.equ ST_LEN, -16
.equ ST_APTR, -8
.equ ST_ALEN, -24
.equ ST_BPTR, -40
.equ ST_BLEN, -32

.equ STDOUT, 1
.equ SYSCALL_WRITE, 4
.equ LINUX_SYSCALL, 0x80

.equ LONG_SIZE, 8

.equ temp1, %rax
.equ temp2, %r11
.equ len, %rdi
.equ ptr, %rsi
.equ alen, %rdi
.equ aptr, %rsi
.equ blen, %rdx
.equ bptr, %rcx

.text

.globl msort
.type msort, @function

# msort(size_t len, long *ptr)
msort:
    pushq   %rbp
    movq    %rsp, %rbp

show_leftmost:
    movq    (ptr), temp1

base_case:
    cmpq    $1, len
    je      out

save_args:
    pushq   ptr                 # save args before recursion
    pushq   len

calc_len_a:
    shr     len
    pushq   len                 # new length a saved on stack

calc_len_b:
    movq    ST_LEN(%rbp), temp1
    subq    len, temp1   
    pushq   temp1               # new length b saved on stack

calc_ptb:
    leaq    (ptr, len, LONG_SIZE), temp1
    pushq   temp1               # new ptr b saved on stack

msort_a:
    call    msort

msort_b:
    movq    ST_BPTR(%rbp), ptr
    movq    ST_BLEN(%rbp), len
    call    msort

merge_ab:
    movq    ST_BPTR(%rbp), bptr
    movq    ST_BLEN(%rbp), blen
    movq    ST_APTR(%rbp), aptr
    movq    ST_ALEN(%rbp), alen
    call    merge

out:
    movq    %rbp, %rsp
    popq    %rbp
    ret

.equ ST_ABLEN, -8

.equ atail, %rax
.equ btail, %r11

# merge(size_t alen, long *aptr, size_t blen, long *bptr)
# beginning at far right of combined section of a:b, merge
# sorted subsequences onto the stack
merge:
    pushq   %rbp
    movq    %rsp, %rbp

merge_save_ab_size:
    movq    alen, temp1
    addq    blen, temp1
    pushq   temp1

    movq    -LONG_SIZE(aptr, alen, LONG_SIZE), atail
    movq    -LONG_SIZE(bptr, blen, LONG_SIZE), btail

merge_loop:
    cmpq    atail, btail
    jl      merge_process_a

merge_process_b:                # btail >= atail. decrement blen.
    pushq   btail

    decq    blen
    je      merge_a_head        # if we are done with b, entire sequence is sorted

    movq    -LONG_SIZE(bptr, blen, LONG_SIZE), btail
    jmp     merge_loop

merge_process_a:                # atail > btail. 
    pushq   atail

    decq    alen
    je      merge_b_head

    movq    -LONG_SIZE(aptr, alen, LONG_SIZE), atail
    jmp     merge_loop

merge_a_head:                   # b is depleted, push rest of a to stack
    pushq    -LONG_SIZE(aptr, alen, LONG_SIZE)
    decq    alen
    je      merge_reconstruct_sequence
    jmp     merge_a_head
    
merge_b_head:
    pushq    -LONG_SIZE(bptr, blen, LONG_SIZE)
    decq    blen
    je      merge_reconstruct_sequence
    jmp     merge_b_head

merge_reconstruct_sequence:
    movq    ST_ABLEN(%rbp), temp2   # length of entire sequence
    movq    $0, temp1

merge_reconstruct_loop:
    popq    (aptr, temp1, LONG_SIZE)
    incq    temp1
    cmpq    temp1, temp2
    jne     merge_reconstruct_loop

merge_out:
    movq    %rbp, %rsp
    popq    %rbp
    ret
