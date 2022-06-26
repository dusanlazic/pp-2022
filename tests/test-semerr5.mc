//OPIS: continue van foreach iskaza
int main() {
    int d;
    int niz[7];
    niz = { 3, 1, 4, 1, 5, 9, 2 };
    
    continue;

    d = 0;
    foreach (int e : niz) {
        d = 1;
    }

    return d;
}
