//OPIS: više foreach petlji
//RETURN: 27
int main() {
    int a;
    int prvi[7];
    int drugi[10];

    prvi = { 3, 1, 4, 1, 5, 9, 2 };
    drugi = { 1, 2, 3, 4, 5, 6, 5, 4, 3, 2};
    
    a = 0;
    foreach (int e : prvi) {
        a = a + 1;
    }

    foreach (int e : drugi) {
        a = a + 2;
    }

    return a;
}
