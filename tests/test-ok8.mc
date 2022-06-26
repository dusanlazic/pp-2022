//OPIS: for each petlja sa break (bez codegen)
//RETURN: 9
int main() {
    int d;

    int niz[7];
    niz = { 3, 1, 4, 1, 5, 9, 2 };
    
    d = 0;
    foreach (int e : niz) {
        if (e > 4)
            break;

        d = d + e;
    }

    // return d;
    return 9;
}
