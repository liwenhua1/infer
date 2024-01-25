#include <stdio.h>

int main() {
    // Write C code here
    printf("Hello world");

    return 0;
}


int* foo(int* x) {
   return x;
}

// void bug(int* y){
//     if (*y>66){
//     int *q = NULL;
//     foo(q);
//     *y = 55;}
//     *y = 56;
// }

%over-approximation (OX), can
%help ensure program correctness and thus prove
%the absence of program bugs. Its dual, 
%incorrectness logic based on  
%surprisingly 
%Hoare logic
%% To achieve the objective of the latter,
%% %% Finding real bugs in program code require
%% incorrectness specifications must be provided.
%To date, incorrectness logic has yet to be systematically 
%formalized for object-oriented programming (OOP), where 
%class inheritance and method overriding are extra challenges. 
%the correctness of
%
Incorrectness logic (IL) based on under-approximation (UX) 
has been shown to be effective at finding
%% its capability to prove instances of execution 
%% errors and can thus effectively find
real program bugs. 
%% Systematically
Formalizing IL for object-oriented 
programs (OOP) is additionally challenged
%% by
%% due to 
%% the aspects of
by the need to support \emph{class inheritance} 
and \emph{method overriding}. 
Previously, a principled approach
%% principles
for verifying OOP had been formulated 
via a novel UX proof system. 
However, these UX specifications were expected to be provided
manually which will hamper the users.
%% manual effort for specification annotations 
%% is usually assumed to be given. 
To make the current UX verification techniques more practical
for OOP programs;
in this work, we design specification inference rules via bi-abduction and specialise the inter-procedural call rules for OOP. In particular, we infer static specifications for calls which can be resolved statically (static dispatching) and address 
\emph{inheritance} 
and \emph{method overriding} (dynamic dispatching) %% for OOP aspects through the
via dynamic specifications. 
%% More specifically, we develop
At its core, we formalise the
{\em projection principle} that gurantees the validity of dynamic specifications; The {\em type constrains propogation} that can selectively trim dynamic specifications for sound reasoning of method call and support the class-cast-exception detection.
To demonstrate its feasibility, we prototype 
the proposed UX specification inference for OOP in {\toolname}. 
%prove its soundness and report on case studies. 
Our experimental results show that,
{\toolname} can detect more errors (null-pointer-exceptions) comparing with the state-of-the-art tool. {\toolname} can also report class-casting-exceptions in real-world projects. To the best of our knowledge, 
and 