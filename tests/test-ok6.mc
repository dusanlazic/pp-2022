//OPIS: for each petlja
//RETURN: 25
int main() {
    int a;
    int b;
    int c;
    int d;

    int niz[7] = { 3, 1, 4, 1, 5, 9, 2 };
    
    d = 0;
    foreach (int e in niz) {
        d = d + e;
    }

    return d;
}
