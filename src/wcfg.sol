// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico, lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15;

contract WCFG {
  // --- Auth ---
  mapping (address => uint) public wards;
  function rely(address usr) public auth { wards[usr] = 1; }
  function deny(address usr) public auth { wards[usr] = 0; }
  modifier auth { require(wards[msg.sender] == 1); _; }

  // --- ERC20 Data ---
  string  public constant name     = "Centrifuge Wrapped Token";
  string  public constant symbol   = "wCFG";
  string  public constant version  = "1";
  uint8   public constant decimals = 18;
  uint256 public totalSupply;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  mapping (address => uint)                      public balanceOf;
  mapping (address => mapping (address => uint)) public allowance;

  event Approval(address indexed src, address indexed usr, uint wcfg);
  event Transfer(address indexed src, address indexed dst, uint wcfg);

  // --- Math ---
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "math-add-overflow");
  }
  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "math-sub-underflow");
  }

  constructor(uint256 chainId_) public {
    wards[msg.sender] = 1;
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId_,
        address(this)
      )
    );
  }

  // --- ERC20 ---
  function transfer(address dst, uint wcfg) external returns (bool) {
    return transferFrom(msg.sender, dst, wcfg);
  }
  function transferFrom(address src, address dst, uint wcfg)
  public returns (bool)
  {
    require(balanceOf[src] >= wcfg, "cent/insufficient-balance");
    if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
      require(allowance[src][msg.sender] >= wcfg, "cent/insufficient-allowance");
      allowance[src][msg.sender] = sub(allowance[src][msg.sender], wcfg);
    }
    balanceOf[src] = sub(balanceOf[src], wcfg);
    balanceOf[dst] = add(balanceOf[dst], wcfg);
    emit Transfer(src, dst, wcfg);
    return true;
  }
  function mint(address usr, uint wcfg) external auth {
    balanceOf[usr] = add(balanceOf[usr], wcfg);
    totalSupply    = add(totalSupply, wcfg);
    emit Transfer(address(0), usr, wcfg);
  }
  function burn(address usr, uint wcfg) public {
    require(balanceOf[usr] >= wcfg, "cent/insufficient-balance");
    if (usr != msg.sender && allowance[usr][msg.sender] != uint(-1)) {
      require(allowance[usr][msg.sender] >= wcfg, "cent/insufficient-allowance");
      allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wcfg);
    }
    balanceOf[usr] = sub(balanceOf[usr], wcfg);
    totalSupply    = sub(totalSupply, wcfg);
    emit Transfer(usr, address(0), wcfg);
  }
  function approve(address usr, uint wcfg) external returns (bool) {
    allowance[msg.sender][usr] = wcfg;
    emit Approval(msg.sender, usr, wcfg);
    return true;
  }

  // --- Alias ---
  function burnFrom(address usr, uint wcfg) external {
    burn(usr, wcfg);
  }
  function push(address usr, uint wcfg) external {
    transferFrom(msg.sender, usr, wcfg);
  }
  function pull(address usr, uint wcfg) external {
    transferFrom(usr, msg.sender, wcfg);
  }
  function move(address src, address dst, uint wcfg) external {
    transferFrom(src, dst, wcfg);
  }

  // --- Approve by signature ---
  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'cent/past-deadline');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'cent/invalid-sig');
    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }
}
