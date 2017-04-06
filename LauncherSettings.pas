unit LauncherSettings;

interface

const
  // Путь в %APPDATA%:
  LocalWorkingFolder: string = '.FMXL3';

  // Путь в реестре, где будут храниться настройки (HKCU//Software//RegistryPath):
  RegistryPath: string = 'FMXL3';

  // Путь к рабочей папке на сервере (там, где лежит веб-часть):
  ServerWorkingFolder: string = 'http://myserver.com/fmx/';

  // Путь к рабочей папке на сервере (там, где лежат клиенты и Java):
  ServerWorkingFolderDownload: string = 'http://myserver.com/fmx/';

  // Ссылка для регистрации на сайте. Пустая строка - регистрация через лаунчер.
  RegisterLink: string = 'http://myserver.com/register.html';

  // Пароль от дополнительных SFX-архивов
  SFXPassword: string = 'vnbdsh4395hgbcskj2';

  // Ключ шифрования (должен совпадать с ключом в веб-части!):
  EncryptionKey: AnsiString = 'FMXL3';

  // Ключ шифрования пароля в реестре:
  PasswordKey: AnsiString = 'The best choise - use XOR, man!';

  // Интервал между обновлением данных мониторинга в миллисекундах:
  MonitoringInterval: Integer = 10000;

  // Версия лаунчера:
  LauncherVersion: Integer = 3;


implementation

end.
