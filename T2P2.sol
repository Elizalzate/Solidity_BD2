pragma solidity ^0.8.17;
contract  apuestasCowboyDreams {

    // Estructura de una apuesta
    struct apuesta {
        address direccionApostador;
        uint codigoCaballo;
        uint codigoCarrera;
        uint valorApostado;
    }

    // Declaración de enumeración con los estados válidos de cada carrera
    enum State {Creada, Registrada, Terminada}

    // Variables
    address public anfitrion;

    // Mappings para guardar los datos de las carreras y los caballos
    mapping (uint => string) public carrerasCreadas;            // mapping para guardar las carreras creadas con su respectivo nombre
    mapping (uint => string) public caballosRegistrados;        // mapping para guardar los caballos registrados con su respectivo nombre
    mapping (uint => uint) public caballosEnCarreras;           // mapping para guardar los caballos registrados en cada carrera
    mapping (uint => State) public estadoCarreras;              // mapping para guardar el estado de cada carrera creada
    mapping (address => uint) public balances;                  // mappingpara guardar los saldos de cada dirección (usuario)

    // Modificadores
    modifier soloAnfitrion() {
        require(msg.sender == anfitrion);
        _;
    }

    // Constructor: se crea una instancia de la casa de apuestas
    constructor() public {
        anfitrion = msg.sender;                                 // Dirección del invocador (anfitrion)
    }

    // Funcion para crear carreras e el mapping carrerasCreadas
    function crearCarrera(uint codigoCarrera, string memory _nombreCarrera) public

}