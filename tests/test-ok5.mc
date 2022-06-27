//OPIS: for each petlja
//RETURN: 7
int main() {
    int i;
    int niz[7];

    niz = { 3, 1, 4, 1, 5, 9, 2 };
    
    i = 0;
    foreach (int e : niz) {
        i = i + 1;
    }

    return i;
}
