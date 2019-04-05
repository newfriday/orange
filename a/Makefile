SRC:=real_mode.asm
BIN:=$(subst .asm,.bin,$(SRC))
DIS:=$(subst .asm,.dis,$(SRC))
IMG:=$(subst .asm,.img,$(SRC))

.PHONY : everything

everything : $(BIN)
	dd if=$(BIN) of=a.img conv=notrunc

$(BIN) : $(SRC)
	nasm $< -o $@
	ndisasm -o 0x7c00 $@ > $(DIS)

clean:
	rm -f $(BIN) $(IMG)
