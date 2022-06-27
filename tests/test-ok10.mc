//OPIS: pristup elementu niza kroz koji se iterira - ne radi :(
//RETURN: 59
int main() {
    int sum;
    int niz[12];

    niz = { 1, 1, 2, 8, 9, 9, 7, 2, 9, 9, 8, 1 };
    
    sum = 0;
    foreach (int e : niz) {
        if (e < 7)
            continue;

        sum = sum + e;
    }

    return sum;
}
