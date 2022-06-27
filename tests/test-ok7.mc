//OPIS: for each petlja sa continue
//RETURN: 2
int main() {
    int i;
    int a;
    int niz[7];

    niz = { 3, 1, 4, 1, 5, 9, 2 };
    
    i = 0;
    a = 0;
    foreach (int e : niz) {
        if (i <= 4) {
            i = i + 1;
            continue;
        }

        a = a + 1;
        i = i + 1;
    }

    return a;
}
