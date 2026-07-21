#include <windows.h>

int APIENTRY
WinMain(HINSTANCE hInst,
        HINSTANCE hInstPrev,
        PSTR cmdline,
        int cmdshow)
{
    MessageBox(0, "This is Handmade Hero", "Handmade Hero",
            MB_OK|MB_ICONINFORMATION);

    return(0);
}
