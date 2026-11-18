# Cafezinho

App de barra de menus do macOS que liga e desliga o `caffeinate` com um clique.

- Ligar sem limite ou por 15 min, 30 min, 1 h, 2 h, 4 h ou 8 h
- Escolher as opções do `caffeinate`: tela acesa (`-d`), inatividade (`-i`), disco (`-m`) e carregador (`-s`)
- Trocar uma opção com ele ligado religa na hora, mantendo o tempo que faltava
- Abrir ao iniciar o Mac
- O ícone da xícara fica cheio enquanto o Mac está sendo mantido acordado

Se o app fechar ou travar, o `caffeinate` morre junto (`-w`), então o Mac nunca fica preso acordado.

## Instalar

Precisa do Xcode ou das Command Line Tools (`xcode-select --install`) e do macOS 13 ou mais novo.

```sh
./build.sh instalar
```

Gera o `Cafezinho.app`, copia para `/Applications` e abre.

## Limite conhecido

Com a tampa fechada e sem carregador, o macOS dorme de qualquer jeito: o `caffeinate` não segura esse caso.
