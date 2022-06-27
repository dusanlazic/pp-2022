//OPIS: razmak u foreach
int main() {
    int a;
    int prvi[7];
    int drugi[10];

    prvi = { 3, 1, 4, 1, 5, 9, 2 };
    drugi = { 1, 2, 3, 4, 5, 6, 5, 4, 3, 2};
    
    a = 0;
    for each (int e : prvi) {
        a = a + e;
    }

    return a;
}
