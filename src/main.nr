use dep::std::ec::tecurve::affine::Point as Gaffine;
use dep::std::ec;

global bjj_a = 168700;
global bjj_d = 168696;


fn main( packed_public_key: pub [u8;32]) { 
    let public_key = unpack_point(packed_public_key);
}

#[test]
fn test_bug() {
    let packed_public_key = [220,159,159,219,116,109,15,7,176,4,204,67,22,227,73,90,88,87,11,144,102,20,153,248,166,166,105,111,244,21,107,170];
    main(packed_public_key);
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

pub fn unpack_point(public_key: [u8; 32]) -> Gaffine 
{
  let mut y_array = public_key;
  let mut point: Gaffine = Gaffine::new(0,0);
  let mut sign = false;
  if((y_array[31] & 0x80) != 0) {
    sign = true;
    y_array[31] &= 0x7f;
  }

  point.y = from_rpr_le(y_array);
  let recovered_y_slice = point.y.to_le_bytes(32); 
  let mut recovered_y_array: [u8;32] = [0;32];
  for i in 0..32 {
     recovered_y_array[i]=recovered_y_slice[i];
  }
  assert(recovered_y_array==y_array,"The packed public key is invalid"); // Important check to get unicity of the packed public key, otherwise a malicious user could generate several packed keys for the same unpacked public key by adding a multiple of p to y

  let mut y2 = point.y * point.y;
  let xa = 1-y2;
  let xb = bjj_a - (bjj_d * y2);
  let x2 = xa / xb;
  point.x = ec::sqrt(x2);

  let pm1d2 = -1 / 2;
  let sign2 = lt_bytes32(pm1d2, point.x);

  if(sign!=sign2) {  // discrepancy compared to circomlibjs here probably due to the Montgomery modular form conversion in circomlibjs/ffwasm
     point.x = -point.x;
  } 
  point // the unpacked public key
}

fn lt_bytes32(x: Field, y: Field) -> bool {
    let x_bytes = x.to_le_bytes(32);
    let y_bytes = y.to_le_bytes(32);
    let mut x_is_lt = false;
    let mut done = false;
    for i in 0..32 {
        if (!done) {
            let x_byte = x_bytes[31 - i] as u8;
            let y_byte = y_bytes[31 - i] as u8;
            let bytes_match = x_byte == y_byte;
            if !bytes_match {
                x_is_lt = x_byte < y_byte;
                done = true;
            }
        }
    }
    x_is_lt
}