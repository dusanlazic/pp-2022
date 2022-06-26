//OPIS: pristup elementu niza preko indeksa
//RETURN: 6
int main() {
    int a;
    int b;
    int c;
    int d;

    int niz[7];
    niz[0] = 3;
    niz[3] = 1;
    niz[6] = 2;
    
    a = niz[0];
    b = niz[3];
    c = niz[6];

    d = a + b + c;

    return d;
}
