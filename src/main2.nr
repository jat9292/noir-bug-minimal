use dep::std::ec::tecurve::affine::Point as Gaffine;
use dep::biguint::BigUint56;
use dep::std::ec;

global bjj_a = 168700;
global bjj_d = 168696;


fn main( packed_public_key: pub [Field;32]) { 
    let mut packed_public_key_u8: [u8;32] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]; // for some reason nargo 0.17 and 0.18 is not able to verify the circuit without this type conversion
    for i in 0..32 {
        packed_public_key_u8[i] = packed_public_key[i] as u8;
    }
    let public_key = unpack_point(packed_public_key_u8);
}

#[test]
fn test_bug() {
    let packed_public_key = [220,159,159,219,116,109,15,7,176,4,204,67,22,227,73,90,88,87,11,144,102,20,153,248,166,166,105,111,244,21,107,170];
    let mut packed_public_key_Field: [Field;32]  = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    for i in 0..32 {
        packed_public_key_Field[i] = packed_public_key[i] as Field;
    }
    main(packed_public_key_Field);
}

fn from_rpr_le(public_key: [u8;32]) -> Field {
  let mut y : Field = 0;
  let mut v : Field = 1;
  for i in 0..32 {
      y += public_key[i] as Field * v;
      v *= 256;
  }
  y
}

fn unpack_point(public_key: [u8; 32]) -> Gaffine 
{
  let mut y_array = public_key;
  let mut point: Gaffine = Gaffine::new(0,0);
  let mut sign = false;
  if((y_array[31] & 0x80) != 0) {
    sign = true;
    y_array[31] &= 0x7f;
  }

  /// Checking the validity of the public key to ensure unicity
  let mut y_slice: [u8] = [];
  for i in 0..32 {
    y_slice=y_slice.push_back(y_array[i]);
  }
  let yBigUint = BigUint56::from_bytes(y_slice);
  let pBigUint = (BigUint56::from_bytes((-1).to_le_bytes(32)).add(BigUint56::from_bytes((1).to_le_bytes(32)))); // p in BigUint format (so it is non-null)
  assert(yBigUint.lt(pBigUint), "The packed public key is invalid"); // Important check to get unicity of the packed public key, otherwise a malicious user could generate several packed keys for the same unpacked public key by adding a multiple of p to y

  point.y = from_rpr_le(y_array);

  let mut y2 = point.y * point.y;
  let xa = 1-y2;
  let xb = bjj_a - (bjj_d * y2);
  let x2 = xa / xb;
  point.x = ec::sqrt(x2);

  let pm1d2 = -1 / 2;
  let sign2 = (BigUint56::from_bytes(point.x.to_le_bytes(32))
      .gt(BigUint56::from_bytes(pm1d2.to_le_bytes(32))));

  if(sign!=sign2) {  // discrepancy compared to circomlibjs here probably due to the Montgomery modular form conversion in circomlibjs/ffwasm
     point.x = -point.x;
  } 

  point
}