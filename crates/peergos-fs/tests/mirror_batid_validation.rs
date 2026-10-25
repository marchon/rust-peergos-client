//! Validation for the signup mirror-BAT id.
//!
//! The Java server (`MirrorCoreNode.startMirror`, `completePaidMirror`,
//! `migrateUser`) rejects a mirror BAT unless `BatId.sha256(bat) == id`
//! ("Invalid BAT id for BAT"). This signs up against the in-process mock server,
//! reads back the mirror BAT the client registered, and applies that same check.

use peergos_core::auth::{BatId, BatWithId};
use peergos_cbor::CborObject;
use peergos_fs::UserContext;
use peergos_mock_server::MockServer;

#[tokio::test]
async fn signup_mirror_bat_passes_java_server_check() {
    let server = MockServer::new();
    let (poster, store, mutable) = server.connect();
    UserContext::sign_up("mirroruser", "mirrorpw", None, poster.clone(), store, mutable)
        .await
        .expect("sign up");

    let raw = poster
        .get("peergos/v0/bats/getUserBats?username=mirroruser")
        .await
        .expect("getUserBats");
    let list = match CborObject::from_bytes(&raw).expect("cbor") {
        CborObject::List(l) => l,
        other => panic!("expected list, got {other:?}"),
    };
    assert_eq!(list.len(), 1, "signup should register exactly one mirror BAT");
    let bwid = BatWithId::from_cbor(&list[0]).expect("BatWithId");
    let expected = BatId::sha256(&bwid.bat).expect("sha256 id");
    let calc = bwid.bat.calculate_id().expect("calculate_id");
    println!("registered mirror id : {}", bwid.id().id);
    println!("BatId.sha256(bat)    : {}", expected.id);
    println!("Bat.calculate_id()   : {}", calc.id);
    assert_eq!(
        bwid.id(),
        expected,
        "Invalid BAT id for BAT: server check BatId.sha256(bat) == id would reject this mirror BAT"
    );
}
