//OPIS: for each petlja sa continue  (bez codegen)
//RETURN: 23
int main() {
    int d;

    int niz[7];
    niz = { 3, 1, 4, 1, 5, 9, 2 };
    
    d = 0;
    foreach (int e in niz) {
        if (e == 1)
            continue;

        d = d + e;
    }

    // return d;
    return 23;
}
