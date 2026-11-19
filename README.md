# Cafezinho

[![CI](https://github.com/LeoFalco/cafezinho/actions/workflows/ci.yml/badge.svg)](https://github.com/LeoFalco/cafezinho/actions/workflows/ci.yml)

App de barra de menus do macOS que liga e desliga o `caffeinate` com um clique.

- Ligar sem limite ou por 15 min, 30 min, 1 h, 2 h, 4 h ou 8 h
- Escolher as opções do `caffeinate`: tela acesa (`-d`), inatividade (`-i`), disco (`-m`) e carregador (`-s`)
- Trocar uma opção com ele ligado religa na hora, mantendo o tempo que faltava
- Abrir ao iniciar o Mac
- O ícone da xícara fica cheio enquanto o Mac está sendo mantido acordado

Se o app fechar ou travar, o `caffeinate` morre junto (`-w`), então o Mac nunca fica preso acordado.

## Instalar

macOS 13 ou mais novo, Apple Silicon ou Intel:

```sh
curl -fsSL https://raw.githubusercontent.com/LeoFalco/cafezinho/main/install.sh | sh
```

Baixa a última versão publicada, coloca em `/Applications` e abre. Rodar de novo atualiza.

O app não é notarizado pela Apple. Se baixar o `Cafezinho.zip` da página de releases pelo navegador, o macOS vai bloquear a abertura: libere com `xattr -dr com.apple.quarantine /Applications/Cafezinho.app`.

### A partir do código

Precisa do Xcode ou das Command Line Tools (`xcode-select --install`).

```sh
./build.sh install   # gera, copia para /Applications e abre
./test.sh            # roda os testes
```

## Desenvolvimento

- `Sources/CafezinhoCore`: a lógica (`Caffeinator`), que monta os argumentos e controla o processo do `caffeinate`
- `Sources/Cafezinho`: o app SwiftUI da barra de menus
- `Tests/CafezinhoCoreTests`: testes com Swift Testing, que sobem o `caffeinate` de verdade
- `tools/make-icon.swift`: gera o PNG do ícone; converta para `.icns` com `sips` e `iconutil`

O CI roda os testes e gera o app universal a cada push. Para publicar uma versão, crie uma tag `vX.Y.Z` e envie: o CI anexa o `Cafezinho.zip` à release, que é o que o `install.sh` baixa.

## Limite conhecido

Fechar a tampa põe o Mac para dormir mesmo no carregador, salvo com monitor externo ligado (modo clamshell): o `caffeinate` não impede isso.
