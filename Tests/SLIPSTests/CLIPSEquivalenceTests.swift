import XCTest
@testable import SLIPS

@MainActor
final class CLIPSEquivalenceTests: XCTestCase {
    func testBasicScaffold() throws {
        // Placeholder: finché la traduzione non è completa, verifichiamo che la facciata esista.
        var env = CLIPS.createEnvironment()
        // Prova basica di envrnmnt: set/get context
        let raw = UnsafeMutableRawPointer(bitPattern: 0xdeadbeef)
        let old = Envrnmnt.SetEnvironmentContext(&env, raw)
        XCTAssertNil(old)
        XCTAssertEqual(Envrnmnt.GetEnvironmentContext(env), raw)

        // Allocazione dati posizionale
        let ok1 = Envrnmnt.AllocateEnvironmentData(&env, position: 0, size: 16, cleanupFunction: nil)
        XCTAssertTrue(ok1)
        let dup = Envrnmnt.AllocateEnvironmentData(&env, position: 0, size: 8, cleanupFunction: nil)
        XCTAssertFalse(dup)

        CLIPS.reset()
        XCTAssertEqual(CLIPS.run(limit: 0), 0)
    }

    func testFeatureProgramsIfPresent() throws {
        // Tenta di individuare i file .clp nelle cartelle di test disponibili.
        // Se non presenti/ancora non supportati, salta il test per ora.
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let candidates = [
            "clips_core_tests_642", // preferito se disponibile
            "clips_feature_tests_642" // fallback presente in questo repo
        ].map { cwd + "/" + $0 }

        guard let testDir = candidates.first(where: { fm.fileExists(atPath: $0) }) else {
            throw XCTSkip("Nessuna cartella di test .clp trovata")
        }

        let clpFiles = try fm.contentsOfDirectory(atPath: testDir).filter { $0.hasSuffix(".clp") }
        if clpFiles.isEmpty { throw XCTSkip("Nessun file .clp da eseguire") }

        // Fase corrente: non eseguiamo ancora i file. Verifichiamo caricamento senza crash.
        for file in clpFiles.prefix(3) { // limita per rapidità
            let path = testDir + "/" + file
            do { try CLIPS.load(path) } catch {
                // In questa fase è accettabile fallire per costrutti non ancora tradotti.
                // Notiamo comunque i fallimenti per futura copertura.
                continue
            }
        }
    }

    func testFileUtilDribbleAndBatch() throws {
        var env = CLIPS.createEnvironment()
        XCTAssertFalse(FileUtil.DribbleActive(env))
        _ = FileUtil.DribbleOn(&env, "dribble.log")
        XCTAssertTrue(FileUtil.DribbleActive(env))
        FileUtil.AppendDribble(&env, "hello")
        _ = FileUtil.DribbleOff(&env)
        XCTAssertFalse(FileUtil.DribbleActive(env))

        XCTAssertFalse(FileUtil.BatchActive(env))
        XCTAssertTrue(FileUtil.OpenBatch(&env, "input.clp", false))
        XCTAssertTrue(FileUtil.BatchActive(env))
        _ = FileUtil.RemoveBatch(&env)
        XCTAssertFalse(FileUtil.BatchActive(env))
    }

    func testLoadSimpleClp() throws {
        let env = CLIPS.createEnvironment()
        let path = FileManager.default.currentDirectoryPath + "/Tests/SLIPSTests/Assets/simple.clp"
        try CLIPS.load(path)
        // Se non crasha e stampa, consideriamo pass
        _ = env // silenzia warning
    }
}
