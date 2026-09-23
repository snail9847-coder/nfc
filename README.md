# NFC Tools для iPhone (Swift + Core NFC)

Полный исходный код нативного iOS-приложения, повторяющего NFC Tools,
плюс автоматическая облачная сборка `.ipa` на виртуальном Mac через
GitHub Actions — весь процесс запускается с Windows, свой Mac не нужен.

## Возможности
- Чтение NFC-меток (NDEF): технологии, размер, записи
- Запись на метки: текст, URL, SMS, гео-позиция
- NFC Задачи: набор действий при поднесении метки
- Очистка метки

## Сборка .ipa (с Windows, без Mac)

1. Установите [Git](https://git-scm.com) и создайте аккаунт на GitHub, если их нет.
2. Создайте на github.com пустой репозиторий (Public, без README).
3. В PowerShell:
   ```powershell
   cd C:\nfc-tools-ios
   git init
   git add .
   git commit -m "NFC Tools iOS"
   git branch -M main
   git remote add origin https://github.com/ВАШ_ЛОГИН/nfc-tools-ios.git
   git push -u origin main
   ```
4. Откройте репозиторий на GitHub → вкладка **Actions** → сборка **Build unsigned IPA**
   запустится автоматически (или запустите вручную кнопкой Run workflow).
5. Через 5–10 минут откройте завершённую сборку → **Artifacts** → скачайте
   `NFCTools-unsigned-ipa` (внутри файл `NFCTools-unsigned.ipa`).

## Подпись и установка на iPhone

Скачанный `.ipa` неподписанный. Подпишите и установите его через **Sideloadly**
(sideloadly.io, работает на Windows):

1. Установите Sideloadly и iTunes (или приложение Apple Devices из Microsoft Store).
2. Подключите iPhone кабелем, откройте Sideloadly.
3. Перетащите `NFCTools-unsigned.ipa` в окно, укажите свой Apple ID и пароль
   (при включённом 2FA — app-specific пароль, создаётся на appleid.apple.com).
   3.1 (если планируете бесплатный Apple ID) в Sideloadly заранее включите опцию
   «Inject entitlements» — для NFC нужен ключ
   `com.apple.developer.nfc-reader-session-formats: [TAG]`, иначе Core NFC откажется работать.
4. Нажмите Start — Sideloadly сам подпишет приложение и установит его на телефон.
5. На iPhone: Настройки → Основные → VPN и управление устройством → доверять вашему Apple ID.

## Важно
- Обычный ПК физически не может собрать iOS-приложение локально (компилятор Swift
  и iOS SDK есть только под macOS), поэтому сборка идёт на macOS-раннере GitHub Actions — бесплатно.
- С бесплатным Apple ID приложение живёт 7 дней, потом просто переустановите через Sideloadly.
- NFC на iPhone читает/пишет только NDEF-метки (NTAG, Mifare Ultralight) — ограничение Core NFC.
- Если при запуске сканирования появляется ошибка «Missing required entitlement» —
  значит entitlement NFC не попал в подпись: проверьте, что включили пункт 3.1.

## Структура
- `NFC Tools/App.swift` — точка входа, вкладки
- `NFC Tools/ReadView.swift` — чтение меток
- `NFC Tools/WriteView.swift` — запись на метки
- `NFC Tools/TasksView.swift` — NFC Задачи
- `NFC Tools/NFCManager.swift` — вся логика Core NFC
- `.github/workflows/build-ipa.yml` — облачная сборка `.ipa`
