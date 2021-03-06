// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title ProjectFactory
 * @dev Factory for creating projects
 */
contract ProjectFactory {
    CrowdFunding[] public deployedProjects;

    /// @notice Deploy a new project
    /// @dev Creates a new project and adds it to deployedProjects
    function createProject(uint256 minimum) public {
        CrowdFunding newProject = new CrowdFunding(minimum, msg.sender);
        deployedProjects.push(newProject);
    }

    /// @notice Gets the deployed projects
    /// @dev Returns the deployedProjects
    function getDeployedProjects() public view returns (CrowdFunding[] memory) {
        return deployedProjects;
    }
}

/**
 * @title CrowdFunding
 * @dev CrowdFunding is a contract that allows multiple parties to contribute to a single project.
 */
contract CrowdFunding {
    // struct type to represent a Request
    struct Request {
        string description; // description of request
        uint256 value; // amount requested in request
        address payable recipient; // address of vendor/recipient whom money will be sent
        bool complete; // True if request is completed
        uint256 approvalCount; // number of approvals
        mapping(address => bool) approvals; // mapping of address to bool indicating if they approved
    }

    uint256 numRequests;

    mapping(uint256 => Request) public requests;

    // state variable of type address containing manager's address
    address public manager;

    //state variable of type uint contating minimum contribution amount
    uint256 public minContribution;

    // address to bool mapping for approvers
    mapping(address => bool) public approvers;

    // state variable to store number of approvers
    uint256 public approversCount;

    // modifier onlyByManager is a modifier that checks if the sender is the manager
    modifier onlyByManager() {
        require(
            msg.sender == manager,
            "Only the manager can create new requests."
        );
        _;
    }

    // Contract constructor: set manager, set minimum contribution
    constructor(uint256 _minContribution, address _manager) {
        manager = _manager;
        minContribution = _minContribution;
    }

    /// @notice function to accept contribution and set the approvers
    /// @dev Accepts incoming contributions and adds msg.sender as an approver.
    function contribute() public payable {
        // checking if the incoming contribution amount is greater than or equal to minimum contribution
        require(
            msg.value >= minContribution,
            "Contibution must be greater than or equal to minimum value"
        );

        approvers[msg.sender] = true;
        approversCount++;
    }

    /// @notice function to create a spend request
    /// @dev Creates a new request and adds it to requests
    /// @param _description description of request
    /// @param _value amount asked in request
    /// @param _recipient address of vendor/recipient whom money will be sent
    function createRequest(
        string memory _description,
        uint256 _value,
        address payable _recipient
    ) public onlyByManager {
        Request storage newRequest = requests[numRequests++];
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
    }

    /// @notice function to approve a request
    /// @dev Checks msg.sender to approve the request and make sures one vote per approver per request.
    /// @param _requestIndex index of request to be approved
    function approveRequest(uint256 _requestIndex) public {
        Request storage request = requests[_requestIndex];

        require(
            approvers[msg.sender],
            "Only contributors can approve requests."
        );

        require(
            !request.approvals[msg.sender],
            "You have already voted for this request"
        );

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    /// @notice function to finalize a request
    /// @dev Finalizes a request by sending the money to the recipient.
    /// @param _requestIndex index of request to be finalized
    function finalizeRequest(uint256 _requestIndex) public onlyByManager {
        Request storage request = requests[_requestIndex];

        require(
            request.approvalCount > (approversCount / 2),
            "More approvals needed to finalize request"
        );

        require(!(request.complete), "Request is already finalized");

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    /// @notice function to get summary of request
    /// @dev Returns the summary of a request
    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            minContribution,
            address(this).balance,
            numRequests,
            approversCount,
            manager
        );
    }

    /// @notice function to get request count
    /// @dev Returns the number of requests
    function getRequestsCount() public view returns (uint256) {
        return numRequests;
    }
}
