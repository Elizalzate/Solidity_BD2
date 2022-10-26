pragma solidity ^0.8.17;
contract  apuestasCowboyDreams {

    // Declaración de enumeración con los estados válidos de cada carrera
    enum State {Creada, Registrada, Terminada}

    // Estructura de un apostador
    struct Apostador {
        address direccionApostador;
        uint balance;
    }

    // Estructura de una carrera
    struct Carrera {
        string nombreCarrera;                                   // variable para guardar el nombre de la carrera
        uint Nroale;                                            // numero aleatorio que determinará al ganador de la carrera
        State estadoCarrera;                                    // variable para guardar el estado de la carrera
        uint caballoGanador;                                    // variable para guardar el caballo ganador de la carrera
        uint[] caballosRegistrados_carrera;                     // array para guardar los caballos registrados en la carrera, indices de 1 a 5
        address[] apostadoresGanadores;                         // array para guardar los apostadores que ganaron la apuesta
        mapping (address => uint) premioGanadores;              // mapping para guardar los apostadores ganadores con el dinero que ganó cada uno
    }

    // Variables
    address public anfitrion;                                   // direccion del anfitrion
    uint[] codigoCarreras;                                      // array para guardar los códigos de las carreras creadas
    uint[] codigoCaballos;                                      // array para guardar los códigos de los caballos registrados

    // Mappings para guardar los datos de las carreras y los caballos
    mapping (uint => Carrera) public carrerasRegistradas;       // mapping para guardar las carreras creadas, en donde el índice es su código
    mapping (uint => string) public caballosRegistrados;        // mapping para guardar los caballos registrados con su respectivo nombre
    mapping (uint => uint) public caballosEnCarreras;           // mapping para guardar los caballos registrados en cada carrera
    mapping (address => Apostador) public balances;             // mapping para guardar los apostadores y sus saldos

    // Modificadores
    modifier soloAnfitrion() {
        require(msg.sender == anfitrion);
        _;
    }

    modifier enEstado(State _state, uint _codigoCarrera) {
        require(getEstadoCarrera(_codigoCarrera) == _state);
        _;
    }

    modifier esGanador(uint _codigoCarrera, address _direccionApostador) {
        require(getCarrera(_codigoCarrera).apostadoresGanadores[_direccionApostador] > 0);
        _;
    }

    // Constructor: se crea una instancia de la casa de apuestas
    constructor() public {
        anfitrion = msg.sender;                                 // Dirección del invocador (anfitrion)
    }

    // Funcion para obtener una carrera determinada
    function getCarrera(uint _codigoCarrera) public returns (Carrera memory _carrera) {
        return carrerasRegistradas[_codigoCarrera];
    }

    // Funcion para obtener la cantidad de carreras creadas en la casa de apuestas
    function getCantidadCarreras() public returns (uint numCarreras) {
        return codigoCarreras.length;
    }

    // Funcion para obtener la cantidad de caballos inscritos en una determinada carrera
    function getCaballosInscritosCarrera(uint _codigoCarrera) public returns (uint[] memory _caballos) {
        return getCarrera(_codigoCarrera).caballosRegistrados_carrera;
    }

    // Funcion para obtener la cantidad de caballos registrados en la casa de apuestas
    function getAllCaballosInscritos() public returns (uint[] memory _caballos) {
        return codigoCaballos;
    }

    // Funcion para obtener el estado de una carrera
    function getEstadoCarrera(uint _codigoCarrera) public returns (State _estado) {
        return getCarrera(_codigoCarrera).estadoCarrera;
    }

    // Funcion para obtener el caballo ganador de una carrera ya terminada
    function getCaballoGanador(uint _codigoCarrera) public enEstado(State.Terminada, _codigoCarrera)  
    returns(uint _caballoGanador) {
        return getCarrera(_codigoCarrera).caballoGanador;
    }

    // Funcion para obtener los apostadores ganadores de una carrera ya terminada
    function getApostadoresGanadores(uint _codigoCarrera) public enEstado(State.Terminada, _codigoCarrera) 
    returns (address[] memory _apostadoresGanadores) {        
        return getCarrera(_codigoCarrera).apostadoresGanadores;
    }

    // Funcion para obtener el dinero de un apostador
    function getPremioGanador(uint _codigoCarrera, address _direccionGanador) public esGanador(_codigoCarrera, _direccionGanador)
    returns (uint _premio) {
        return getCarrera(_codigoCarrera).premioGanadores[_direccionGanador];
    }
}