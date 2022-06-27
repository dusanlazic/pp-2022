//OPIS: for each petlja sa break
//RETURN: 3
int main() {
    int i;
    int niz[7];

    niz = { 3, 1, 4, 1, 5, 9, 2 };
    
    i = 0;
    foreach (int e : niz) {
        if (i >= 3)
            break;

        i = i + 1;
    }

    return i;
}
