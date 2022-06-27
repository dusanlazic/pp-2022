//OPIS: pristup elementu niza preko indeksa
//RETURN: 207
int main() {
    int a[7];
    int b[7];
    int ea;
    int eb;

    a = { 100, 101, 102, 103, 104, 105, 106 };
    b[4] = 104;

    ea = a[3];
    eb = b[4];

    return ea + eb;
}
