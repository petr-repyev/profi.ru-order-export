# profi.ru-order-export
Выгрузка заказов PROFI.RU

Запуск программы

./order-id.sh token [input.csv]

**token** - значение переменной bo_tkn из окружения JS (можно взять из переменной INITIAL.profileScreenData.backofficeRatingUrl )

**input.csv** - utf8 текстовый файл с построчным указанием ID заказов. Например для https://profi.ru/backoffice/r.php?id=39162179 значение будет 39162179
