pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
contract  apuestasCowboyDreams {

    // Declaración de enumeración con los estados válidos de cada carrera
    enum State {Creada, Registrada, Terminada}

    // Estructura de un apostador
    struct Apostador {
        address payable direccionApostador;
    }

    // Estructura de una apuesta
    struct Apuesta {
        address payable direccionApostador;
        uint montoApostado;
        uint caballoApostado;
    }

    // Estructura de una carrera
    struct Carrera {
        string nombreCarrera;                                   // variable para guardar el nombre de la carrera
        uint Nroale;                                            // numero aleatorio que determinará al ganador de la carrera
        State estadoCarrera;                                    // variable para guardar el estado de la carrera
        uint[] caballosRegistrados_carrera;                     // array para guardar los caballos registrados en la carrera
        Apostador[] apostadores;                                // array para guardar las direcciones de los apostadores participantes
        Apostador[] apostadoresGanadores;                       // array para guardar los apostadores que ganaron la apuesta
        mapping (address => Apuesta) apuestas;                  // mapping para guardar las apuestas realizadas por cada apostador
        mapping (address => uint) premioGanadores;              // mapping para guardar los apostadores ganadores con el dinero que ganó cada uno
    }

    // Variables
    address payable public anfitrion;                           // direccion del anfitrion
    uint[] codigoCarreras;                                      // array para guardar los códigos de las carreras creadas
    uint[] codigoCaballos;                                      // array para guardar los códigos de los caballos registrados

    // Mappings para guardar los datos de las carreras y los caballos
    mapping (uint => Carrera) public carreras;                  // mapping para guardar las carreras creadas, en donde el índice es su código
    mapping (uint => string) public caballosRegistrados;        // mapping para guardar los caballos registrados con su respectivo nombre
    mapping (uint => uint) public caballosEnCarreras;           // mapping para guardar los caballos registrados en cada carrera
    mapping (address => uint) public balances;                  // mapping para guardar las direcciones (usuarios) y sus respectivos saldos

    // Modificadores
    modifier soloAnfitrion() {
        require(msg.sender == anfitrion);
        _;
    }

    modifier enEstado(State _state, uint _codigoCarrera) {
        require(getEstadoCarrera(_codigoCarrera) == _state);
        _;
    }

    modifier esGanador(uint _codigoCarrera, address payable _direccionApostador) {
        bool _found = false;
        Apostador[] memory ganadores = carreras[_codigoCarrera].apostadoresGanadores;
        for (uint i=0; i<ganadores.length; i++){
            if(_direccionApostador == ganadores[i].direccionApostador) {
                _found = true;
            }
        }
        require(_found);
        _;
    }

    // Eventos
    event carreraCreada();

    event carreraRegistrada();

    event carreraTerminada(uint carrera, string nombreCarrera, uint caballoGanador, string nombreCaballo, uint ethersApostados);

    event caballoRegistrado();

    event caballoRegistradoCarrera();

    event apuestaRealizada();

    event apuestaGanadora(address apostadorGanador, uint apuestaRealizada, uint premio);


    // Constructor: se crea una instancia de la casa de apuestas
    constructor(address payable _anfitrion) public {
        anfitrion = _anfitrion;                                 // Dirección del invocador (anfitrion)
        balances[anfitrion] = 0;
    }



    // Funcion para obtener la cantidad de carreras creadas en la casa de apuestas
    function getCantidadCarreras() public returns (uint numCarreras) {
        return codigoCarreras.length;
    }

    // Funcion para obtener la cantidad de caballos inscritos en una determinada carrera
    function getCaballosInscritosCarrera(uint _codigoCarrera) public returns (uint[] memory _caballos) {
        return carreras[_codigoCarrera].caballosRegistrados_carrera;
    }

    // Funcion para obtener la cantidad de caballos registrados en la casa de apuestas
    function getAllCaballosInscritos() public returns (uint[] memory _caballos) {
        return codigoCaballos;
    }

    // Funcion para obtener el estado de una carrera
    function getEstadoCarrera(uint _codigoCarrera) public returns (State _estado) {
        return carreras[_codigoCarrera].estadoCarrera;
    }

    // Funcion para obtener el caballo ganador de una carrera ya terminada
    function getCaballoGanador(uint _codigoCarrera) public enEstado(State.Terminada, _codigoCarrera)  
    returns(uint _caballoGanador) {
        Carrera memory _carrera = carreras[_codigoCarrera];
        uint _Nroale = _carrera.Nroale;
        return _carrera.caballosRegistrados_carrera[_Nroale];
    }

    // Funcion para obtener los apostadores ganadores de una carrera ya terminada
    function getApostadoresGanadores(uint _codigoCarrera) public enEstado(State.Terminada, _codigoCarrera) 
    returns (Apostador[] memory _apostadoresGanadores) {        
        return carreras[_codigoCarrera].apostadoresGanadores;
    }

    // Funcion para obtener el dinero de un apostador
    function getPremioGanador(uint _codigoCarrera, address payable _direccionGanador) public esGanador(_codigoCarrera, _direccionGanador)
    enEstado(State.Terminada, _codigoCarrera) returns (uint _premio) {
        return carreras[_codigoCarrera].premioGanadores[_direccionGanador];
    }

    // Funcion para obtener los premios de los apostadores ganadores de una carrera
    function getPremiosGanadores(uint _codigoCarrera) public enEstado(State.Terminada, _codigoCarrera) returns (uint[] memory _premios){
        Carrera storage _carrera = carreras[_codigoCarrera];
        Apostador[] memory _apostadoresGanadores = _carrera.apostadoresGanadores;
        uint[] memory premiosGanadores = new uint[](_apostadoresGanadores.length);
        for (uint i=0; i<_apostadoresGanadores.length; i++){
            address payable _apostadorGanador = _apostadoresGanadores[i].direccionApostador;
            premiosGanadores[i] =_carrera.premioGanadores[_apostadorGanador];
        }
        return premiosGanadores;
    }

    // Funcion para generar un numero aleatorio perteneciente al rango (0, _range-1)
    // Funcion para generar un numero aleatorio perteneciente al rango (0, _range-1)
    function random(uint _range) private view returns (uint) {
    uint randomHash = uint(keccak256(abi.encodePacked(now)));
    return randomHash % _range;
    } 

    // Funcion para culminar una carrera
    function terminarCarrera(uint _codigoCarrera) public payable enEstado(State.Registrada, _codigoCarrera) {
        Carrera storage _carrera = carreras[_codigoCarrera];
        // Cambiamos el estado de la carrera a terminada
        _carrera.estadoCarrera = State.Terminada;
        uint[] memory _caballosRegistrados = _carrera.caballosRegistrados_carrera;
        uint ethersTotales = 0;
        uint ethersCaballoGanador = 0;
        // Generamos un numero aleatorio entre 0 y N-1, sumamos 1 para que nuestro numero aleatorio este entre 1 y N.
        _carrera.Nroale = random(_caballosRegistrados.length) + 1;           
        uint caballoGanador = getCaballoGanador(_codigoCarrera);
        // Sumamos todas las apuestas realizadas en la carrera y guardamos los apostadores ganadores
        for (uint i=0; i<_carrera.apostadores.length; i++) {
            Apuesta memory _apuesta = _carrera.apuestas[_carrera.apostadores[i].direccionApostador];
            ethersTotales += _apuesta.montoApostado;
            if (_apuesta.caballoApostado == caballoGanador) {
                Apostador memory _apostador;
                _apostador.direccionApostador = _apuesta.direccionApostador;
                _carrera.apostadoresGanadores.push(_apostador);
                ethersCaballoGanador += _apuesta.montoApostado;
            }
        }
        uint montoAnfitrion = ethersTotales/4;
        for (uint i=0; i<_carrera.apostadoresGanadores.length; i++) {
            address payable _apostadorGanador = _carrera.apostadoresGanadores[i].direccionApostador;
            Apuesta memory _apuesta = _carrera.apuestas[_apostadorGanador];
            uint premioGanador = (_apuesta.montoApostado/ethersCaballoGanador)*ethersTotales;
            _carrera.premioGanadores[_apostadorGanador] = premioGanador;
            _apostadorGanador.transfer(premioGanador);
            balances[_apostadorGanador] += premioGanador;
            emit apuestaGanadora(_apostadorGanador, _apuesta.montoApostado, premioGanador);
        }
        anfitrion.transfer(montoAnfitrion);
        string memory nombreCaballoGanador = caballosRegistrados[caballoGanador];
        emit carreraTerminada(_codigoCarrera, _carrera.nombreCarrera, caballoGanador, nombreCaballoGanador, ethersTotales);
    }
}