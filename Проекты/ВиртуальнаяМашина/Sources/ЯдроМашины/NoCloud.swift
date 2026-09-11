import Foundation
import Virtualization
import Darwin

public enum НастройкаГостя {
    public static func создать(идентификатор: String, ключКлиента: String, ключХоста: String, закрытыйКлючХоста: String) throws -> String {
        guard UUID(uuidString: идентификатор) != nil,
              ключКлиента.hasPrefix("ssh-ed25519 "), ключХоста.hasPrefix("ssh-ed25519 "),
              !закрытыйКлючХоста.isEmpty else { throw ОшибкаМашины("Неверные идентичность или ключи NoCloud.") }
        func строка(_ текст: String) throws -> String {
            let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.withoutEscapingSlashes]
            return String(decoding: try кодировщик.encode(текст.trimmingCharacters(in: .whitespacesAndNewlines)), as: UTF8.self)
        }
        let закрытый = закрытыйКлючХоста.split(separator: "\n", omittingEmptySubsequences: false).map { "    " + $0 }.joined(separator: "\n")
        return """
        #cloud-config
        hostname: fum-linux
        manage_etc_hosts: true
        disable_root: true
        ssh_pwauth: false
        ssh_deletekeys: true
        users:
          - name: ubuntu
            lock_passwd: true
            shell: /bin/bash
            sudo: ["ALL=(ALL) NOPASSWD:ALL"]
            ssh_authorized_keys:
              - \(try строка(ключКлиента))
        ssh_keys:
          ed25519_public: \(try строка(ключХоста))
          ed25519_private: |
        \(закрытый)
        write_files:
          - path: /etc/fum-vm-id
            permissions: '0444'
            content: \(try строка(идентификатор))
          - path: /etc/systemd/system/fum-vsock.service
            permissions: '0644'
            content: \(try строка(РесурсыГостя.текст("fum-vsock.service")))
          - path: /etc/systemd/system/fum-vsock.socket
            permissions: '0644'
            content: \(try строка(РесурсыГостя.текст("fum-vsock.socket")))
        runcmd:
          - [systemctl, daemon-reload]
          - [systemctl, enable, --now, fum-vsock.socket]
          - [systemctl, enable, --now, serial-getty@hvc0.service]
        """ + "\n"
    }
}

extension ПодготовкаUbuntu {
    public func идентичность() throws {
        let имя = "идентичность"
        func проверить() throws -> Bool {
            var сведения = stat()
            if fstatat(хранилище.дескриптор, имя, &сведения, AT_SYMLINK_NOFOLLOW) != 0 {
                guard errno == ENOENT else { throw ОшибкаМашины("Не удалось проверить идентичность VM.") }
                return false
            }
            guard сведения.st_mode & S_IFMT == S_IFDIR, сведения.st_uid == getuid(), сведения.st_mode & 0o077 == 0 else {
                throw ОшибкаМашины("Небезопасный каталог постоянной идентичности VM.")
            }
            let каталог = try открытьКаталог(путь(имя)); defer { close(каталог) }
            for файл in ["клиент", "клиент.pub", "хост", "хост.pub", "known_hosts", "ssh_config", "машина.bin", "mac.txt", "efi.bin", "seed.iso"] {
                var сведения = stat()
                guard fstatat(каталог, файл, &сведения, AT_SYMLINK_NOFOLLOW) == 0,
                      сведения.st_mode & S_IFMT == S_IFREG, сведения.st_uid == getuid(), сведения.st_nlink == 1,
                      сведения.st_mode & 0o077 == 0, сведения.st_size > 0 else {
                    throw ОшибкаМашины("Постоянная идентичность неполна или изменена: \(файл). Автоматическое пересоздание запрещено.")
                }
            }
            return true
        }
        try этап("идентичность", проверить: проверить) {
            let временное = "идентичность-" + UUID().uuidString.lowercased()
            guard mkdirat(хранилище.дескриптор, временное, 0o700) == 0 else { throw ОшибкаМашины("Не удалось начать создание идентичности.") }
            let каталог = URL(fileURLWithPath: путь(временное))
            func сохранить(_ имя: String, _ байты: Data) throws { try байты.write(to: каталог.appendingPathComponent(имя), options: .withoutOverwriting) }
            for имя in ["клиент", "хост"] {
                try метрики.команда("создание ключа «\(имя)»", "/usr/bin/ssh-keygen", ["-q", "-t", "ed25519", "-N", "", "-C", "fum-vm-" + имя, "-f", каталог.appendingPathComponent(имя).path])
            }
            func текст(_ имя: String) throws -> String { try String(contentsOf: каталог.appendingPathComponent(имя), encoding: .utf8) }
            let публичныйХост = try текст("хост.pub").trimmingCharacters(in: .whitespacesAndNewlines)
            try сохранить("known_hosts", Data(("fum-" + хранилище.паспорт.идентификатор + " " + публичныйХост + "\n").utf8))
            func кавычки(_ значение: String) -> String { "\"" + значение.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\"" }
            let настройка = """
            Host *
                HostName 127.0.0.1
                User ubuntu
                HostKeyAlias fum-\(хранилище.паспорт.идентификатор)
                IdentityFile \(кавычки(путь("идентичность/клиент")))
                UserKnownHostsFile \(кавычки(путь("идентичность/known_hosts")))
                GlobalKnownHostsFile /dev/null
                StrictHostKeyChecking yes
                IdentitiesOnly yes
                IdentityAgent none
                UpdateHostKeys no
                BatchMode yes
                ConnectTimeout 5
                ServerAliveInterval 10
                ServerAliveCountMax 3
            """ + "\n"
            try сохранить("ssh_config", Data(настройка.utf8))
            try сохранить("машина.bin", VZGenericMachineIdentifier().dataRepresentation)
            try сохранить("mac.txt", Data(VZMACAddress.randomLocallyAdministered().string.utf8))
            _ = try VZEFIVariableStore(creatingVariableStoreAt: каталог.appendingPathComponent("efi.bin"))
            let seedКаталог = каталог.appendingPathComponent("seed")
            try FileManager.default.createDirectory(at: seedКаталог, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            let данные = try НастройкаГостя.создать(идентификатор: хранилище.паспорт.идентификатор,
                ключКлиента: текст("клиент.pub"), ключХоста: публичныйХост, закрытыйКлючХоста: текст("хост"))
            try Data(данные.utf8).write(to: seedКаталог.appendingPathComponent("user-data"), options: .withoutOverwriting)
            try Data(("instance-id: " + хранилище.паспорт.идентификатор + "\nlocal-hostname: fum-linux\n").utf8).write(to: seedКаталог.appendingPathComponent("meta-data"), options: .withoutOverwriting)
            try метрики.команда("создание NoCloud CIDATA", "/usr/bin/hdiutil", ["makehybrid", "-iso", "-joliet", "-default-volume-name", "CIDATA", "-o", каталог.appendingPathComponent("seed.iso").path, seedКаталог.path], предел: 60)
            // Производители файлов могут явно устанавливать 0644 вопреки umask.
            for имяФайла in ["клиент", "клиент.pub", "хост", "хост.pub", "known_hosts", "ssh_config", "машина.bin", "mac.txt", "efi.bin", "seed.iso", "seed/user-data", "seed/meta-data"] {
                let файл = Darwin.open(каталог.appendingPathComponent(имяФайла).path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
                guard файл >= 0 else { throw ОшибкаМашины("Не удалось открыть созданную идентичность.") }
                let успех = fchmod(файл, 0o600) == 0 && fsync(файл) == 0
                close(файл)
                guard успех else { throw ОшибкаМашины("Не удалось долговечно защитить идентичность.") }
            }
            let каталогДанных = try открытьКаталог(seedКаталог.path), каталогИдентичности = try открытьКаталог(каталог.path)
            defer { close(каталогДанных); close(каталогИдентичности) }
            guard fsync(каталогДанных) == 0, fsync(каталогИдентичности) == 0 else { throw ОшибкаМашины("Не удалось сохранить каталоги идентичности.") }
            guard renameatx_np(хранилище.дескриптор, временное, хранилище.дескриптор, имя, UInt32(RENAME_EXCL)) == 0,
                  fsync(хранилище.дескриптор) == 0 else { throw ОшибкаМашины("Не удалось установить постоянную идентичность без замены.") }
        }
    }
}
