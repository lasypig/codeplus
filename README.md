# CodePlus

> This a vim plugin to speed up coding with language C.

## How to install?

Copy codeplus.vim to your vim plugin directory:

`cp codeplus.vim ~/.vim/plugin`

## How to use?
Assume you have the following struct:
```c
typedef struct {
	int left;
	int top;
	int right;
	int bottom;
} rect_t;
```

If you move your cursor to a line like this:

```c
struct rect_t rect;
```

and press `<F7>`, I will generate following code for you:
```c
rect.left   = ;
rect.top    = ;
rect.right  = ;
rect.bottom = ;
```
If I could do nothing for you, I will show message bellow.

## Notice

This plugin depends on tag files, plese run `ctags -R .` first.





