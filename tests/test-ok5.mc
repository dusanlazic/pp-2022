//OPIS: pristup elementu niza preko indeksa
//RETURN: 6
int main() {
    int a;
    int b;
    int c;
    int d;

    int niz[7] = { 3, 1, 4, 1, 5, 9, 2 };
    
    a = niz[0];
    b = niz[3];
    c = niz[6];

    d = a + b + c;

    return d;
}
