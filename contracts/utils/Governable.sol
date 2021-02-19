// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/proxy/Initializable.sol";

contract Governable is Initializable {

  event GovernanceUpdated(address governance);

  bytes32 internal constant _GOVERNANCE_SLOT = 0xcda9a6b4b9d6bf2129b27a60d3a668c00468526758d2daf3ad15c6d27199cbc2;
  bytes32 internal constant _PENDING_GOVERNANCE_SLOT = 0x9ab8554274867f10a81dfb4a6983625500f54f8ea6d2d4c54b9c7b2ca234c7e6;

  modifier onlyGovernance() {
    require(_governance() == msg.sender, "Not governance");
    _;
  }

  constructor() public {
    assert(_GOVERNANCE_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.governable.governance")) - 1));
    assert(_PENDING_GOVERNANCE_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.governable.pendingGovernance")) - 1));
  }

  function initializeGovernance(address _governance) public initializer {
    _setGovernance(_governance);
  }

  function _setGovernance(address _governance) private {
    bytes32 slot = _GOVERNANCE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _governance)
    }
  }

  function _setPendingGovernance(address _pendingGovernance) private {
    bytes32 slot = _PENDING_GOVERNANCE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _pendingGovernance)
    }
  }

  function updateGovernance(address _newGovernance) public onlyGovernance {
    require(_newGovernance != address(0), "new governance shouldn't be empty");
    _setPendingGovernance(_newGovernance);
  }

  function acceptGovernance() public {
    require(_pendingGovernance() == msg.sender, "Not pending governance");
    _setGovernance(msg.sender);
    emit GovernanceUpdated(msg.sender);
  }

  function _governance() internal view returns (address str) {
    bytes32 slot = _GOVERNANCE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function _pendingGovernance() internal view returns (address str) {
    bytes32 slot = _PENDING_GOVERNANCE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return _governance();
  }
}
