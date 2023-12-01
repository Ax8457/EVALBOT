;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)



		AREA    |.text|, CODE, READONLY
			
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5; les ports sont innitialisé comme entrée donc on dit que toute broche est
										; à 0 et broche 4 à 1 et broche 5 à 1 alors la somme en heaxa donne x30 car b4: 0x10 et b5: 0x20

BROCHE6_7			EQU 	0xC0		; bouton poussoir 1

BROCHE0_1			EQU     0x03        ; bumper 1 et 2 sur broche 1et 2 0x01 et 0x00000010, il faudra indiqué qu'il fonctionne comme le bouton pousoir



; blinking frequency
DUREE   			EQU     0x002FFFFF

		ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche


__main	

; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F où sont branchés les leds (0x28 == 0b101000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6]


		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED

;DIR POUR DIRE SI CEST entrée ou sortie 
;pur pour dir si c'est une résistance de pull sur notre entrée sortie
        ldr r9, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r9]
		
		ldr r9, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r9]
		
		ldr r9, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r9]
		
		mov r2, #0x000       					;; pour eteindre LED
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r9, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 


		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Switcher 1

		ldr r7, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7		
        str r0, [r7]
		
		ldr r7, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r7]     
		
		ldr r7, = GPIO_PORTD_BASE + (BROCHE6_7<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher

		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Switcher 
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumpers

		ldr r8, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r8]
		
		ldr r8, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r8]     
		
		ldr r8, = GPIO_PORTE_BASE + (BROCHE0_1<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Bumpers 


		;; BL Branchement vers un lien (sous programme)

		; Initialisation 
		BL	MOTEUR_INIT	
		mov r12, #0x00

loop
	mov r12, #0x00
loop2

		ldr r11,[r7] 
		CMP r11, #0x80   ;;switch 1
		BEQ compteurled
		
		ldr r10,[r7]
		CMP r10, #0x40    ;;stwich 2
		BEQ quelleinstr
		

		b loop2

	
compteurled	
		ADD r12,r12,#0x01
		str r3, [r9]    			     
        ldr r1, = DUREE
		
wait
		subs r1, #1
        bne wait
		
		str r2, [r9]   
        ldr r1, = DUREE  
		
wait2   
		subs r1, #1
        bne wait2
		
		b loop2
		
quelleinstr
		CMP r12, #0X1
		BEQ instr1
		CMP r12, #0x2
		BEQ instr2
		
		b loop2

instr1
		BL  MOTEUR_DROIT_ON
		BL  MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_AVANT
		
		ldr r4, [r8]
		CMP r4, #0x01
		BEQ demitourdroit
		CMP r4, #0x2
		BEQ demitourgauche
		
		b instr1
		
demitourdroit
		str r3, [r9]    			     
        ldr r1, = DUREE
		
wait3
		subs r1, #1
        bne wait3
		
		str r2, [r9]   
        ldr r1, = DUREE  
		
wait4  
		subs r1, #1
        bne wait4
		
retour 		
		BL	MOTEUR_DROIT_ARRIERE 
		BL  MOTEUR_GAUCHE_OFF
		BL	WAIT
		BL  WAIT
		
		
		b retour

WAIT	ldr r1, =0xAFFFFF		
wait5	subs r1, #1
        bne wait5
		
		b instr1
		
demitourgauche

		str r3, [r9]    			     
        ldr r1, = DUREE
		
wait6
		subs r1, #1
        bne wait6
		
		str r2, [r9]   
        ldr r1, = DUREE  
		
wait7 
		subs r1, #1
        bne wait7
		
retour1 		
		BL	MOTEUR_GAUCHE_ARRIERE 
		BL  MOTEUR_DROIT_OFF
		BL	WAIT1
		BL  WAIT1
		
		
		b retour1

WAIT1	ldr r1, =0xAFFFFF		
wait8	subs r1, #1
        bne wait8
		
		b instr1
		
		b loop
		
		
		
instr2
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		BL MOTEUR_DROIT_ARRIERE
		BL MOTEUR_GAUCHE_ARRIERE
		
		b loop



		
		
	
	
