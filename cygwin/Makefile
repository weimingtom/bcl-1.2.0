CC= gcc
CFLAGS= -g

all : HuffmanEnc.exe HuffmanDec.exe

HuffmanEnc.exe : HuffmanEncTest.o HuffmanEnc.o CStyleFileLdr.o CStyleFileSav.o
	${CC} -o $@  HuffmanEncTest.o HuffmanEnc.o CStyleFileLdr.o CStyleFileSav.o

HuffmanDec.exe : HuffmanDecTest.o HuffmanDec.o CStyleFileLdr.o CStyleFileSav.o 
	${CC} -o $@ HuffmanDecTest.o HuffmanDec.o CStyleFileLdr.o CStyleFileSav.o 
	
clean :
	-rm -f *.exe *_2.txt *.o

test : all
	-rm -f enc_2.txt
	./HuffmanEnc dec.txt enc_2.txt
	diff enc.txt enc.txt
	-rm -f dec_2.txt
	./HuffmanDec enc.txt dec_2.txt
	diff dec.txt dec_2.txt

HuffmanEncTest.o : HuffmanEncTest.c
HuffmanEnc.o : HuffmanEnc.c
HuffmanDecTest.o : HuffmanDecTest.c
HuffmanDec.o : HuffmanDec.c
CStyleFileLdr.o : CStyleFileLdr.c
CStyleFileSav.o : CStyleFileSav.c



