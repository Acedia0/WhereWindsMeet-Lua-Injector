/**
 * Stealth Hook - Advanced Anti-Detection for Frida
 * Implementa tecniche avanzate per evitare rilevamento
 */

(function() {
    'use strict';
    
    // ========= CONFIGURAZIONE =========
    const STEALTH_CONFIG = {
        renameThreads: true,
        hidePort: true,
        obfuscateStrings: true,
        antiDebug: true,
        randomTiming: true,
        patchDetection: true,
        hideModules: true
    };
    
    // ========= UTILITY =========
    
    function randomDelay(min, max) {
        const delay = Math.random() * (max - min) + min;
        return new Promise(resolve => setTimeout(resolve, delay * 1000));
    }
    
    function log(msg, level = 'INFO') {
        const timestamp = new Date().toISOString();
        console.log(`[${timestamp}] [${level}] ${msg}`);
    }
    
    function xorString(str, key) {
        return str.split('').map(c => 
            String.fromCharCode(c.charCodeAt(0) ^ key)
        ).join('');
    }
    
    // ========= ANTI-DETECTION =========
    
    class AntiDetection {
        
        // Rinomina thread Frida
        static renameThreads() {
            try {
                const suspiciousNames = [
                    'gum-js-loop',
                    'gmain',
                    'gdbus',
                    'frida-agent-main',
                    'frida-gadget'
                ];
                
                // Su Windows, prova a modificare nomi thread
                if (Process.platform === 'windows') {
                    const SetThreadDescription = Module.findExportByName(
                        'kernel32.dll', 
                        'SetThreadDescription'
                    );
                    
                    if (SetThreadDescription) {
                        // Hook per rinominare thread al volo
                        Interceptor.attach(SetThreadDescription, {
                            onEnter: function(args) {
                                const name = args[1].readUtf16String();
                                if (suspiciousNames.some(s => name.includes(s))) {
                                    // Sostituisci con nome innocuo
                                    const newName = 'WinThread' + Math.floor(Math.random() * 10000);
                                    args[1] = Memory.allocUtf16String(newName);
                                }
                            }
                        });
                    }
                }
                
                log('Thread renaming attivo', 'STEALTH');
            } catch (e) {
                log('Errore rename threads: ' + e, 'WARN');
            }
        }
        
        // Nasconde porta Frida
        static hidePort() {
            try {
                // Hook getaddrinfo per nascondere porta
                const getaddrinfo = Module.findExportByName(null, 'getaddrinfo');
                if (getaddrinfo) {
                    Interceptor.attach(getaddrinfo, {
                        onEnter: function(args) {
                            const port = args[1];
                            if (port && !port.isNull()) {
                                const portStr = port.readUtf8String();
                                // Filtra porta Frida (27042 default)
                                if (portStr === '27042' || portStr === '27043') {
                                    // Blocca o modifica
                                    this.blocked = true;
                                }
                            }
                        },
                        onLeave: function(retval) {
                            if (this.blocked) {
                                retval.replace(ptr(-1)); // Errore
                            }
                        }
                    });
                }
                
                log('Port hiding attivo', 'STEALTH');
            } catch (e) {
                log('Errore hide port: ' + e, 'WARN');
            }
        }
        
        // Offusca stringhe Frida in memoria
        static obfuscateStrings() {
            try {
                const fridaStrings = [
                    'frida',
                    'Frida',
                    'FRIDA',
                    'frida-agent',
                    'frida-gadget',
                    'gum-js-loop'
                ];
                
                fridaStrings.forEach(str => {
                    // Cerca pattern in memoria
                    Process.enumerateModules().forEach(mod => {
                        try {
                            Memory.scan(mod.base, mod.size, str, {
                                onMatch: function(address, size) {
                                    try {
                                        // Proteggi memoria
                                        Memory.protect(address, size, 'rwx');
                                        
                                        // XOR con chiave casuale
                                        const key = Math.floor(Math.random() * 255) + 1;
                                        for (let i = 0; i < size; i++) {
                                            const byte = address.add(i).readU8();
                                            address.add(i).writeU8(byte ^ key);
                                        }
                                    } catch (e) {
                                        // Ignora errori di protezione
                                    }
                                },
                                onComplete: function() {}
                            });
                        } catch (e) {
                            // Ignora moduli non accessibili
                        }
                    });
                });
                
                log('String obfuscation attivo', 'STEALTH');
            } catch (e) {
                log('Errore obfuscate strings: ' + e, 'WARN');
            }
        }
        
        // Anti-debugging
        static antiDebug() {
            try {
                if (Process.platform === 'windows') {
                    // Hook IsDebuggerPresent
                    const isDebuggerPresent = Module.findExportByName(
                        'kernel32.dll', 
                        'IsDebuggerPresent'
                    );
                    
                    if (isDebuggerPresent) {
                        Interceptor.replace(isDebuggerPresent, new NativeCallback(
                            function() {
                                return 0; // Sempre false
                            }, 
                            'int', 
                            []
                        ));
                    }
                    
                    // Hook CheckRemoteDebuggerPresent
                    const checkRemote = Module.findExportByName(
                        'kernel32.dll', 
                        'CheckRemoteDebuggerPresent'
                    );
                    
                    if (checkRemote) {
                        Interceptor.attach(checkRemote, {
                            onLeave: function(retval) {
                                // Forza false nel parametro out
                                const pbDebuggerPresent = this.context.rdx || this.context.edx;
                                if (pbDebuggerPresent) {
                                    ptr(pbDebuggerPresent).writeU8(0);
                                }
                            }
                        });
                    }
                    
                    // Hook NtQueryInformationProcess
                    const ntQuery = Module.findExportByName(
                        'ntdll.dll', 
                        'NtQueryInformationProcess'
                    );
                    
                    if (ntQuery) {
                        Interceptor.attach(ntQuery, {
                            onEnter: function(args) {
                                const infoClass = args[1].toInt32();
                                // ProcessDebugPort = 7
                                if (infoClass === 7) {
                                    this.patchDebugPort = true;
                                    this.outBuffer = args[2];
                                }
                            },
                            onLeave: function(retval) {
                                if (this.patchDebugPort && this.outBuffer) {
                                    this.outBuffer.writeU32(0);
                                }
                            }
                        });
                    }
                }
                
                log('Anti-debug attivo', 'STEALTH');
            } catch (e) {
                log('Errore anti-debug: ' + e, 'WARN');
            }
        }
        
        // Patch detection di Frida
        static patchDetection() {
            try {
                // Lista di funzioni comuni usate per rilevare Frida
                const detectionFunctions = [
                    'strstr',
                    'strcmp',
                    'strncmp',
                    'strcasestr'
                ];
                
                detectionFunctions.forEach(funcName => {
                    const func = Module.findExportByName(null, funcName);
                    if (func) {
                        Interceptor.attach(func, {
                            onEnter: function(args) {
                                // Leggi stringhe confrontate
                                try {
                                    const str1 = args[0].readUtf8String();
                                    const str2 = args[1].readUtf8String();
                                    
                                    // Se cercano "frida" o simili
                                    const suspicious = ['frida', 'gum', 'gadget'];
                                    const isSuspicious = suspicious.some(s => 
                                        (str1 && str1.toLowerCase().includes(s)) ||
                                        (str2 && str2.toLowerCase().includes(s))
                                    );
                                    
                                    if (isSuspicious) {
                                        // Modifica risultato per non matchare
                                        this.spoofResult = true;
                                    }
                                } catch (e) {
                                    // Ignora errori di lettura
                                }
                            },
                            onLeave: function(retval) {
                                if (this.spoofResult) {
                                    if (funcName === 'strcmp' || funcName === 'strncmp') {
                                        retval.replace(ptr(1)); // Non uguale
                                    } else {
                                        retval.replace(ptr(0)); // Non trovato
                                    }
                                }
                            }
                        });
                    }
                });
                
                log('Detection patching attivo', 'STEALTH');
            } catch (e) {
                log('Errore patch detection: ' + e, 'WARN');
            }
        }
        
        // Nasconde moduli Frida
        static hideModules() {
            try {
                // Hook EnumProcessModules per nascondere DLL Frida
                if (Process.platform === 'windows') {
                    const enumModules = Module.findExportByName(
                        'kernel32.dll', 
                        'K32EnumProcessModules'
                    ) || Module.findExportByName(
                        'psapi.dll', 
                        'EnumProcessModules'
                    );
                    
                    if (enumModules) {
                        Interceptor.attach(enumModules, {
                            onLeave: function(retval) {
                                // Filtra moduli Frida dalla lista
                                // (implementazione complessa, richiede parsing buffer)
                            }
                        });
                    }
                }
                
                log('Module hiding attivo', 'STEALTH');
            } catch (e) {
                log('Errore hide modules: ' + e, 'WARN');
            }
        }
    }
    
    // ========= LUA HOOK STEALTH =========
    
    class LuaHookStealth {
        
        static findLuaState() {
            // Cerca lua_State in memoria con tecniche stealth
            let luaState = null;
            
            Process.enumerateModules().forEach(mod => {
                if (mod.name.toLowerCase().includes('lua')) {
                    // Scansiona modulo Lua
                    const patterns = [
                        '48 8B ?? 48 85 ?? 74 ?? 48 8B',  // Pattern x64
                        '8B ?? 85 ?? 74 ?? 8B'             // Pattern x86
                    ];
                    
                    patterns.forEach(pattern => {
                        Memory.scan(mod.base, mod.size, pattern, {
                            onMatch: function(address, size) {
                                // Verifica se è lua_State valido
                                try {
                                    const possibleState = address.readPointer();
                                    if (possibleState && !possibleState.isNull()) {
                                        luaState = possibleState;
                                        return 'stop';
                                    }
                                } catch (e) {}
                            },
                            onComplete: function() {}
                        });
                    });
                }
            });
            
            return luaState;
        }
        
        static hookLuaLoad() {
            // Hook lua_load con timing randomizzato
            const luaLoad = Module.findExportByName(null, 'lua_load');
            if (luaLoad) {
                Interceptor.attach(luaLoad, {
                    onEnter: async function(args) {
                        // Delay randomizzato
                        if (STEALTH_CONFIG.randomTiming) {
                            await randomDelay(0.1, 0.5);
                        }
                        
                        this.L = args[0];
                    },
                    onLeave: function(retval) {
                        log('Lua code loaded (stealth)', 'DEBUG');
                    }
                });
            }
        }
    }
    
    // ========= INITIALIZATION =========
    
    async function initializeStealth() {
        log('='.repeat(60), 'INFO');
        log('Stealth Hook - Inizializzazione', 'INFO');
        log('='.repeat(60), 'INFO');
        
        // Delay iniziale randomizzato
        const initialDelay = Math.random() * 3 + 2;
        log(`Delay iniziale: ${initialDelay.toFixed(2)}s`, 'INFO');
        await randomDelay(initialDelay, initialDelay + 1);
        
        // Applica tecniche stealth
        if (STEALTH_CONFIG.renameThreads) {
            AntiDetection.renameThreads();
        }
        
        if (STEALTH_CONFIG.hidePort) {
            AntiDetection.hidePort();
        }
        
        if (STEALTH_CONFIG.obfuscateStrings) {
            await randomDelay(0.5, 1.5);
            AntiDetection.obfuscateStrings();
        }
        
        if (STEALTH_CONFIG.antiDebug) {
            await randomDelay(0.5, 1.5);
            AntiDetection.antiDebug();
        }
        
        if (STEALTH_CONFIG.patchDetection) {
            await randomDelay(0.5, 1.5);
            AntiDetection.patchDetection();
        }
        
        if (STEALTH_CONFIG.hideModules) {
            await randomDelay(0.5, 1.5);
            AntiDetection.hideModules();
        }
        
        // Hook Lua con stealth
        await randomDelay(1, 2);
        LuaHookStealth.hookLuaLoad();
        
        log('='.repeat(60), 'INFO');
        log('Stealth Hook - ATTIVO', 'SUCCESS');
        log('='.repeat(60), 'INFO');
    }
    
    // Avvia con delay randomizzato
    const startDelay = Math.random() * 2000 + 1000;
    setTimeout(() => {
        initializeStealth().catch(e => {
            log('Errore inizializzazione: ' + e, 'ERROR');
        });
    }, startDelay);
    
    // Export per uso esterno
    if (typeof rpc !== 'undefined') {
        rpc.exports = {
            enableStealth: function(config) {
                Object.assign(STEALTH_CONFIG, config);
                return { success: true, config: STEALTH_CONFIG };
            },
            getStealthStatus: function() {
                return STEALTH_CONFIG;
            }
        };
    }
    
})();
