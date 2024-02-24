pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CBDC is ERC20 {
    // O endereço da entidade controladora do CBDC
    // É o governo, nesse caso.
    address public enderecoDoGoverno;

    // No solidity não podemos ter futuação, então usamos números inteiros
    // 250 equivalem a 2.5%
    uint public taxaBasicaDeJuros = 250;

    // O governo pode te adicionar em uma lista negra!
    mapping(address => bool) public listaNegra;

    // É uma forma de comprar títulos do tesouro, fazendo staking de crypto.
    // Ou seja, você faz staking e o gov. te paga juros
    mapping(address => uint) private valorInvestidoNoTesouroDireto;

    // Temos um mapeador da data inicial do investimento
    mapping(address => uint) private dataInicialDoInvestimento;

    // Criando eventos para fazer o log de ações dentro do contracto

    // A entidade controladora pode mudar a qualquer momento,
    // A forma de criar logs dentro de um contract é criando eventos
    // Então simplesmente nós disparamos esse evento quando chegado o tempo.
    event AtualizarEnderecoDoGoverno(
        address velhoEnderecoDoGoverno,
        address novoEnderecoDoGoverno
    );
    event AtualizarATaxaDeJuros(uint velhaTaxaDeJuros, uint novaTaxaDeJuros);
    event ImprimirMoedas(uint quantidadeAnterior, uint quantidadeNova);
    event AtualizarListaNegra(address criminoso, bool bloqueado);
    event FazerInvestimendoNoTesouroDireto(address cidadao, uint valor);
    event DesfazerInvestimendoNoTesouroDireto(address cidadao, uint valor);
    event ReivindicarLucroDoInvestimendoNoTesouroDireto(
        address cidadao,
        uint valor
    );

    constructor(
        address _enderecoDoGoverno,
        uint _quantidadeDeMoedasIniciais
    ) ERC20("A modeda do banco central", "DREX") {
        enderecoDoGoverno = _enderecoDoGoverno;
        _mint(enderecoDoGoverno, _quantidadeDeMoedasIniciais);
    }

    function atualizarEnderecoDoGoverno(
        address novoEnderecoDoGoverno
    ) external {
        require(
            msg.sender == enderecoDoGoverno,
            "Voce nao e o dono dessa moeda"
        );
        enderecoDoGoverno = novoEnderecoDoGoverno;
        // Transferir todo o dinheiro que estava no endereço antigo para o novo
        _transfer(
            enderecoDoGoverno,
            novoEnderecoDoGoverno,
            balanceOf(enderecoDoGoverno)
        );
        emit AtualizarEnderecoDoGoverno(
            enderecoDoGoverno,
            novoEnderecoDoGoverno
        );
    }

    function atualizarATaxaDeJuros(uint novaTaxaDeJuros) external {
        require(msg.sender == enderecoDoGoverno, "Tem que ser o dono");
        uint velhaTaxaDeJuros = novaTaxaDeJuros;
        taxaBasicaDeJuros = novaTaxaDeJuros;
        emit AtualizarATaxaDeJuros(velhaTaxaDeJuros, novaTaxaDeJuros);
    }

    // Isso é o que o governo mais gosta de fazer para gerar inflação
    function imprimirMaisMoedas(uint quantidadeDeMoedas) {
        require(msg.sender == enderecoDoGoverno, "So o gov");

        uint quantidadeAtualDeMoedasImpressas = totalSupply();

        // Essa é a quantidade de moedas a MAIS que serão criadas!!!
        // Ou seja, se existiam 10 e a variável quantidadeDeMoedas for 10
        // Então vai ser somado os 10 atuais com os 10 novos
        // Logo serão 20
        _mint(msg.sender, quantidadeDeMoedas);

        emit ImprimirMoedas(quantidadeAtualDeMoedasImpressas, quantidadeNova);
    }

    function fazerInvestimendoNoTesouroDireto(uint valor) {
        require(valor > 0, "O valor tem que ser mais que zero");

        require(
            balanceOf(msg.sender) >= valor,
            "Voce nao tem saldo para investir"
        );

        _transfer(msg.sender, address(this), valor);

        //TODO: entender o resgatar
        if (valorInvestidoNoTesouroDireto[msg.sender] > 0)
            reivindicarLucroDoInvestimendoNoTesouroDireto();

        dataInicialDoInvestimento[msg.sender] = block.timestamp;

        valorInvestidoNoTesouroDireto[msg.sender] += valor;

        emit InvestirNoTesouroDireto(msg.sender, valor);
    }

    function desfazerInvestimendoNoTesouroDireto(valor) external {
        require(valor > 0, "O valor tem que ser maior que zero");

        require(
            valorInvestidoNoTesouroDireto[msg.sender] > 0,
            "Voce nao tem nada investido"
        );

        reivindicarLucroDoInvestimendoNoTesouroDireto();

        valorInvestidoNoTesouroDireto[msg.sender] -= valor;

        _trasfer(address(this), msg.sender, valor);

        emit DesfazerInvestimendoNoTesouroDireto(msg.sender, valor);
    }

    function reivindicarLucroDoInvestimendoNoTesouroDireto() public {
        require(
            valorInvestidoNoTesouroDireto[msg.sender] > 0,
            "Voce deve ter algum valor investido para resgate dos lucros."
        );

        uint tempoDeInvestimentoEmSegundos = block.timestamp -
            dataInicialDoInvestimento[msg.sender];

        uint lucro = (valorInvestidoNoTesouroDireto[msg.sender] *
            tempoDeInvestimentoEmSegundos *
            taxaBasicaDeJuros) /
            10000 /
            3.154e7;

        dataInicialDoInvestimento[msg.sender] = block.timestamp;

        _mint(msg.sender, lucro);

        emit ReivindicarLucroDoInvestimendoNoTesouroDireto(msg.sender, lucro);
    }

    function _transfer(
        address remetente,
        address destinatario,
        uint valor
    ) internal virtual override {
        require(
            listaNegra[remetente] == false,
            "O remetente esta na lista negra"
        );
        require(
            listaNegra[destinatario] == false,
            "O destinatario esta na lista negra"
        );
        super.transfer(remetente, destinatario, valor);
    }
}
