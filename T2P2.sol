pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
contract  apuestasCowboyDreams {

    // Declaración de enumeración con los estados válidos de cada carrera
    enum State {Creada, Registrada, Terminada}

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
        address payable[] apostadores;                          // array para guardar las direcciones de los apostadores participantes
        address payable[] apostadoresGanadores;                 // array para guardar los apostadores que ganaron la apuesta
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

    modifier noAnfitrion() {
        require(msg.sender != anfitrion);
        _;
    }

    modifier enEstado(State _state, uint _codigoCarrera) {
        require(getEstadoCarrera(_codigoCarrera) == _state);
        _;
    }

    modifier esGanador(uint _codigoCarrera, address payable _direccionApostador) {
        bool _found = false;
        address payable[] memory ganadores = carreras[_codigoCarrera].apostadoresGanadores;
        for (uint i=0; i<ganadores.length; i++){
            if(_direccionApostador == ganadores[i]) {
                _found = true;
            }
        }
        require(_found);
        _;
    }

    modifier esCaballoRegistradoCarrera(uint _codigoCarrera, uint _codigoCaballo) {
        bool _found = false;
        uint[] memory caballos = carreras[_codigoCarrera].caballosRegistrados_carrera;
        for (uint i=0; i<caballos.length; i++){
            if(_codigoCaballo == caballos[i]) {
                _found = true;
            }
        }
        require(_found);
        _;
    }

        modifier noEsCaballoRegistradoCarrera(uint _codigoCarrera, uint _codigoCaballo) {
        bool _found = false;
        uint[] memory caballos = carreras[_codigoCarrera].caballosRegistrados_carrera;
        for (uint i=0; i<caballos.length; i++){
            if(_codigoCaballo == caballos[i]) {
                _found = true;
            }
        }
        require(!_found);
        _;
    }

    modifier esCaballoRegistrado(uint _codigoCaballo) {
        bool _found = false;
        for (uint i=0; i<codigoCaballos.length; i++){
            if(_codigoCaballo == codigoCaballos[i]) {
                _found = true;
            }
        }
        require(_found);
        _;
    }

    modifier noEsCaballoRegistrado(uint _codigoCaballo) {
        bool _found = false;
        for (uint i=0; i<codigoCaballos.length; i++){
            if(_codigoCaballo == codigoCaballos[i]) {
                _found = true;
            }
        }
        require(!_found);
        _;
    }

    modifier esCarreraCreada(uint _codigoCarrera) {
        bool _found = false;
        for (uint i=0; i<codigoCarreras.length; i++){
            if(_codigoCarrera == codigoCarreras[i]) {
                _found = true;
            }
        }
        require(_found);
        _;
    }

    modifier noEsCarreraCreada(uint _codigoCarrera) {
        bool _found = false;
        for (uint i=0; i<codigoCarreras.length; i++){
            if(_codigoCarrera == codigoCarreras[i]) {
                _found = true;
            }
        }
        require(!_found);
        _;
    }

    modifier validacionApostador(uint _codigoCarrera, address payable _direccionApostador) {
        bool _found = false;
        address payable[] memory _apostadores = carreras[_codigoCarrera].apostadores;
        for (uint i=0; i<_apostadores.length; i++){
            if(_direccionApostador == _apostadores[i]) {
                _found = true;
            }
        }
        require(!_found, "Ya has apostado en esta carrera, no puedes apostar otra vez");
        _;
    }

    modifier capacidadCaballosCarrera(uint _codigoCarrera) {
        require(carreras[_codigoCarrera].caballosRegistrados_carrera.length < 5,
                "La capacidad máxima de caballos ya ha sido alcanzada en esta carrera");
                _;
    }

    modifier capacidadCaballosRegistro(uint _codigoCarrera) {
    require(carreras[_codigoCarrera].caballosRegistrados_carrera.length >= 2,
            "La capacidad mínima de caballos aún no ha sido alcanzada en esta carrera");
            _;
    }

    // Eventos
    event carreraCreada(uint _codigoCarrera, string _nombreCarrera);

    event carreraRegistrada(uint _codigoCarrera, string _nombreCarrera);

    event carreraTerminada(uint carrera, string nombreCarrera, uint caballoGanador, string nombreCaballo, uint ethersApostados);

    event caballoRegistrado(uint _codigoCaballo, string _nombreCaballo);

    event caballoRegistradoCarrera(uint _codigoCarrera, uint _codigoCaballo);

    event apuestaRealizada(uint _codigoCarrera, uint _codigoCaballo, uint montoApuesta, address payable direccionApostador);

    event apuestaActualizada(uint _codigoCarrera, uint _codigoCaballo, uint montoApuesta, address payable direccionApostador);

    event apuestaGanadora(address apostadorGanador, uint apuestaRealizada, uint premio);


    // Constructor: se crea una instancia de la casa de apuestas
    constructor(address payable _anfitrion) public {
        anfitrion = _anfitrion;                                 // Dirección del invocador (anfitrion)
        balances[anfitrion] = 0;
    }

    function crearCarrera(uint _codigoCarrera, string memory _nombreCarrera) public noEsCarreraCreada(_codigoCarrera) {
        Carrera memory c;
        c.nombreCarrera = _nombreCarrera;
        c.estadoCarrera = State.Creada;
        codigoCarreras.push(_codigoCarrera);
        carreras[_codigoCarrera] = c;
        emit carreraCreada(_codigoCarrera, _nombreCarrera);
    }

    function registrarCaballo(uint _codigoCaballo, string memory _nombreCaballo) public noEsCaballoRegistrado(_codigoCaballo) {
        caballosRegistrados[_codigoCaballo] = _nombreCaballo;
        codigoCaballos.push(_codigoCaballo);
        emit caballoRegistrado(_codigoCaballo, _nombreCaballo);
    }

    function registrarCaballoEnCarrera(uint _codigoCarrera, uint _codigoCaballo) public enEstado(State.Creada, _codigoCarrera) 
    noEsCaballoRegistradoCarrera(_codigoCarrera, _codigoCaballo)  esCaballoRegistrado(_codigoCaballo) capacidadCaballosCarrera(_codigoCarrera) {
        Carrera storage _carrera = carreras[_codigoCarrera];
        _carrera.caballosRegistrados_carrera.push(_codigoCaballo);
        emit caballoRegistradoCarrera(_codigoCarrera, _codigoCaballo);
    }

    function registrarCarrera(uint _codigoCarrera) public enEstado(State.Creada, _codigoCarrera)
    capacidadCaballosRegistro(_codigoCarrera) {
        Carrera storage _carrera = carreras[_codigoCarrera];
        _carrera.estadoCarrera = State.Registrada;
        emit carreraRegistrada(_codigoCarrera, _carrera.nombreCarrera);
    }

    function apostar(uint _codigoCarrera, uint _codigoCaballo, uint montoApuesta) public enEstado(State.Registrada, _codigoCarrera)
    noAnfitrion() esCaballoRegistradoCarrera(_codigoCarrera, _codigoCaballo) validacionApostador(_codigoCarrera, msg.sender) {
        Carrera storage _carrera = carreras[_codigoCarrera];
        Apuesta memory _apuesta;
        _apuesta.direccionApostador = msg.sender;
        _apuesta.montoApostado = montoApuesta;
        _apuesta.caballoApostado = _codigoCaballo;
        _carrera.apostadores.push(msg.sender);
        _carrera.apuestas[msg.sender] = _apuesta;
        emit apuestaRealizada(_codigoCarrera, _codigoCaballo, montoApuesta, msg.sender);
    }

    function actualizarApuesta(uint _codigoCarrera, uint montoActualizado) public enEstado(State.Registrada, _codigoCarrera)
    noAnfitrion() {
        Carrera storage _carrera = carreras[_codigoCarrera];
        address payable[] memory _apostadores = _carrera.apostadores;
        uint caballo;
        for (uint i=0; i<_apostadores.length; i++){
            if (msg.sender == _apostadores[i]){
                _carrera.apuestas[msg.sender].montoApostado = montoActualizado;
                caballo =  _carrera.apuestas[msg.sender].caballoApostado;
            } 
        }
        emit apuestaActualizada(_codigoCarrera, caballo, montoActualizado, msg.sender);
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
    returns (address payable[] memory _apostadoresGanadores) {        
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
        address payable[] memory _apostadoresGanadores = _carrera.apostadoresGanadores;
        uint[] memory premiosGanadores = new uint[](_apostadoresGanadores.length);
        for (uint i=0; i<_apostadoresGanadores.length; i++){
            address payable _apostadorGanador = _apostadoresGanadores[i];
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
            Apuesta memory _apuesta = _carrera.apuestas[_carrera.apostadores[i]];
            ethersTotales += _apuesta.montoApostado;
            if (_apuesta.caballoApostado == caballoGanador) {
                _carrera.apostadoresGanadores.push(_apuesta.direccionApostador);
                ethersCaballoGanador += _apuesta.montoApostado;
            }
        }
        uint montoAnfitrion = ethersTotales/4;
        for (uint i=0; i<_carrera.apostadoresGanadores.length; i++) {
            address payable _apostadorGanador = _carrera.apostadoresGanadores[i];
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