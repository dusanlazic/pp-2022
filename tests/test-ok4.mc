//OPIS: pristup elementu niza preko indeksa
//RETURN: 306
int main() {
    int a;
    int b;
    int c;
    int d;
    int niz[7];
    
    niz[0] = 101;
    niz[3] = 102;
    niz[6] = 103;
    
    a = niz[0];
    b = niz[3];
    c = niz[6];

    d = a + b + c;

    return d;
}
