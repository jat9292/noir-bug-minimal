use dep::std::ec::tecurve::affine::Point as Gaffine;
use dep::biguint::BigUint56;
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

fn unpack_point(public_key: [u8; 32]) -> Gaffine 
{
  let mut y_array = public_key;
  let mut point: Gaffine = Gaffine::new(0,0);
  let mut sign = false;
  if((y_array[31] & 0x80) != 0) {
    sign = true;
    y_array[31] &= 0x7f;
  }

  let mut y_slice: [u8] = [];
  for i in 0..32 {
    y_slice=y_slice.push_back(y_array[i]);
  }
  let yBigUint = BigUint56::from_bytes(y_slice);
  let pBigUint = (BigUint56::from_bytes((-1).to_le_bytes(32)).add(BigUint56::from_bytes((1).to_le_bytes(32))));
  assert(yBigUint.lt(pBigUint), "The packed public key is invalid"); 

  point.y = from_rpr_le(y_array);

  let mut y2 = point.y * point.y;
  let xa = 1-y2;
  let xb = bjj_a - (bjj_d * y2);
  let x2 = xa / xb;
  point.x = ec::sqrt(x2);

  let pm1d2 = -1 / 2;
  let sign2 = (BigUint56::from_bytes(point.x.to_le_bytes(32))
      .gt(BigUint56::from_bytes(pm1d2.to_le_bytes(32))));

  if(sign!=sign2) {
     point.x = -point.x;
  } 
  point
}