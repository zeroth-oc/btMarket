declare let window: any;
import { createContext, useContext, useState } from "react";
import ethers from "ethers";
import Polymarket from "../abis/Polymarket.json";

interface DataContextProps {
  account: string;
  loading: boolean;
  loadWeb3: () => Promise<void>;
  polymarket: any;
}

const DataContext = createContext<DataContextProps>({
  account: "",
  loading: true,
  loadWeb3: async () => {},
  polymarket: null,
});

export const DataProvider: React.FC = ({ children }) => {
  const data = useProviderData();

  return <DataContext.Provider value={data}>{children}</DataContext.Provider>;
};

export const useData = () => useContext<DataContextProps>(DataContext);

export const useProviderData = () => {
  const [loading, setLoading] = useState(true);
  const [account, setAccount] = useState("");
  const [polymarket, setPolymarket] = useState<any>();

  const loadWeb3 = async () => {
    if (window.ethereum) {
      window.web3 = new ethers.providers.Web3Provider(window.ethereum);
      await window.ethereum.enable();
    } else if (window.web3) {
      window.web3 = new ethers.providers.Web3Provider(
        window.web3.currentProvider
      );
    } else {
      window.alert("Non-Eth browser detected. Please consider using MetaMask.");
      return;
    }
    var allAccounts = await window.web3.eth.getAccounts();  
    setAccount(allAccounts[0]);
    await loadBlockchainData();
  };

  const loadBlockchainData = async () => {
    const ethers = window.web3;

    const polymarketData = Polymarket.networks["80001"];

    if (polymarketData) {
      var tempContract = new ethers.Contract(
        Polymarket.abi,
        polymarketData.address
      );
      setPolymarket(tempContract);
    } else {
      window.alert("TestNet not found");
    }
    setTimeout(() => {
      setLoading(false);
    }, 500);
  };

  return {
    account,
    polymarket,
    loading,
    loadWeb3,
  };
};
